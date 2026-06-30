import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/issue_model.dart';
import '../services/ai_service.dart';
import '../services/auth_service.dart';
import '../services/cloudinary_service.dart';
import '../services/issue_service.dart';
import '../services/location_service.dart';
import '../widgets/media_picker_widget.dart';

class ReportIssueScreen extends StatefulWidget {
  /// When provided the screen opens in "edit" mode pre-filled with this report.
  final IssueModel? issueToEdit;

  const ReportIssueScreen({super.key, this.issueToEdit});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedCategory;
  String? _aiPriority;
  String? _aiReason;
  String? _aiConfidence;
  String? _lastAnalyzedTitle;
  String? _lastAnalyzedDescription;
  File? _selectedMedia;
  String? _mediaType;
  Position? _currentPosition;

  bool _isLoading = false;
  bool _isFetchingLocation = false;
  bool _isAnalyzing = false;

  final List<String> _categories = [
    'Pothole',
    'Garbage',
    'Streetlight',
    'Water Leakage',
    'Traffic Issue',
    'Other',
  ];

  final AiService _aiService = AiService();
  final AuthService _authService = AuthService();
  final IssueService _issueService = IssueService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final LocationService _locationService = LocationService();

  bool get _canAnalyze {
    return _titleController.text.trim().length >= 15 &&
        _descriptionController.text.trim().length >= 15;
  }

  bool get _showAiResult {
    return _lastAnalyzedTitle != null &&
        _lastAnalyzedTitle == _titleController.text &&
        _lastAnalyzedDescription == _descriptionController.text;
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red.shade700;
      case 'Medium':
        return Colors.orange.shade800;
      case 'Low':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    IconData? icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.32),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.error, width: 1.6),
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 19, color: colorScheme.onPrimaryContainer),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _priorityChip(String priority) {
    final priorityColor = _priorityColor(priority);
    return Chip(
      avatar: Icon(Icons.flag_rounded, size: 18, color: priorityColor),
      label: Text('$priority priority'),
      labelStyle: TextStyle(color: priorityColor, fontWeight: FontWeight.w700),
      backgroundColor: priorityColor.withValues(alpha: 0.12),
      side: BorderSide(color: priorityColor.withValues(alpha: 0.45)),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }

  void _onTextChanged() {
    setState(() {
      _lastAnalyzedTitle = null;
      _lastAnalyzedDescription = null;
      _aiPriority = null;
      _aiReason = null;
      _aiConfidence = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onTextChanged);
    _descriptionController.addListener(_onTextChanged);
    // Pre-fill when editing an existing report
    final existing = widget.issueToEdit;
    if (existing != null) {
      _titleController.text = existing.title;
      _descriptionController.text = existing.description;
      _selectedCategory = existing.category;
      if (existing.latitude != null && existing.longitude != null) {
        _currentPosition = Position(
          latitude: existing.latitude!,
          longitude: existing.longitude!,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }
    } else {
      _titleController.addListener(_onTextChanged);
      _descriptionController.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _isFetchingLocation = true;
    });

    try {
      final position = await _locationService.getCurrentLocation();
      setState(() {
        _currentPosition = position;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location fetched successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching location: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingLocation = false;
        });
      }
    }
  }

  Future<void> _analyzeWithAi() async {
    if (!_canAnalyze || _isAnalyzing) return;

    final currentTitle = _titleController.text;
    final currentDescription = _descriptionController.text;

    if (currentTitle == _lastAnalyzedTitle &&
        currentDescription == _lastAnalyzedDescription) {
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final result = await _aiService.categorizeIssue(
        title: currentTitle,
        description: currentDescription,
      );
      final decoded = jsonDecode(result);
      final suggestedCategory = decoded is Map<String, dynamic>
          ? decoded['category']
          : null;
      final suggestedPriority = decoded is Map<String, dynamic>
          ? decoded['priority']
          : null;
      final suggestedReason = decoded is Map<String, dynamic>
          ? decoded['reason']
          : null;
      final suggestedConfidence = decoded is Map<String, dynamic>
          ? decoded['confidence']
          : null;

      if (mounted) {
        setState(() {
          _lastAnalyzedTitle = currentTitle;
          _lastAnalyzedDescription = currentDescription;
          _aiPriority = null;
          _aiReason = null;
          _aiConfidence = null;

          if (suggestedCategory is String &&
              _categories.contains(suggestedCategory)) {
            _selectedCategory = suggestedCategory;
          }
          if (suggestedPriority is String &&
              const ['High', 'Medium', 'Low'].contains(suggestedPriority)) {
            _aiPriority = suggestedPriority;
          }
          if (suggestedReason is String && suggestedReason.trim().isNotEmpty) {
            _aiReason = suggestedReason.trim();
          }
          if (suggestedConfidence is String &&
              const ['High', 'Medium', 'Low'].contains(suggestedConfidence)) {
            _aiConfidence = suggestedConfidence;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'AI analysis unavailable. You can still submit manually.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<void> _submitIssue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to report an issue'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? mediaUrl = widget.issueToEdit?.mediaUrl;
      String? mediaType = widget.issueToEdit?.mediaType;

      // 1. Upload new media if user picked a new file
      if (_selectedMedia != null) {
        if (_mediaType == 'image') {
          mediaUrl = await _cloudinaryService.uploadImage(_selectedMedia!);
        } else if (_mediaType == 'video') {
          mediaUrl = await _cloudinaryService.uploadVideo(_selectedMedia!);
        }
        mediaType = _mediaType;

        if (mediaUrl == null) {
          throw Exception('Media upload failed.');
        }
      }

      // 2. Construct Model
      final issue = IssueModel(
        issueId: widget.issueToEdit?.issueId ?? '',
        userId: user.uid,
        userEmail: user.email ?? 'Unknown',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
        status: widget.issueToEdit?.status ?? 'pending',
        priority: (_showAiResult && _aiPriority != null)
            ? _aiPriority!
            : (widget.issueToEdit?.priority ?? 'Medium'),
        createdAt: widget.issueToEdit?.createdAt ?? DateTime.now(),
      );

      // 3. Save to Firestore
      if (widget.issueToEdit != null) {
        await _issueService.updateIssue(issue);
      } else {
        await _issueService.createIssue(issue);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.issueToEdit != null
                ? 'Report updated successfully!'
                : 'Issue reported successfully!'),
          ),
        );
        Navigator.pop(context, true); // return true so callers can refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit issue: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.issueToEdit != null ? 'Edit Report' : 'Report an Issue'),
        centerTitle: false,
        surfaceTintColor: colorScheme.surfaceTint,
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton(
          onPressed: _isLoading ? null : _submitIssue,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _isLoading
                ? const Row(
                    key: ValueKey('loading'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Submitting...'),
                    ],
                  )
                : const Row(
                    key: ValueKey('ready'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.send_rounded),
                      SizedBox(width: 10),
                      Text('Submit Issue'),
                    ],
                  ),
          ),
        ),
      ),
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                const _ReportIntroCard(),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _titleController,
                  onChanged: (_) => _onTextChanged(),
                  decoration: _inputDecoration(
                    label: 'Title',
                    hint: 'Brief summary of the issue',
                    icon: Icons.title_rounded,
                  ),
                  maxLength: 50,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    if (value.trim().length < 5) {
                      return 'Title must be at least 5 characters long';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration(
                    label: 'Category',
                    hint: 'Select issue category',
                    icon: Icons.category_rounded,
                  ),
                  initialValue: _selectedCategory,
                  borderRadius: BorderRadius.circular(16),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select a category' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  onChanged: (_) => _onTextChanged(),
                  decoration: _inputDecoration(
                    label: 'Description',
                    hint: 'Provide details about the issue...',
                    icon: Icons.notes_rounded,
                  ),
                  minLines: 4,
                  maxLines: 5,
                  maxLength: 500,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    if (value.trim().length < 10) {
                      return 'Description must be at least 10 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                if (!_showAiResult) ...[
                  OutlinedButton.icon(
                    onPressed: (_canAnalyze && !_isAnalyzing)
                        ? _analyzeWithAi
                        : null,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: _isAnalyzing
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome_rounded),
                    label: Text(
                      _isAnalyzing ? 'Analyzing issue...' : 'Analyze with AI',
                    ),
                  ),
                  if (!_canAnalyze) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Enter a more detailed title and description for AI analysis.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                ],
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, animation) => SizeTransition(
                    sizeFactor: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: (_showAiResult &&
                      (_aiReason != null || _aiPriority != null))
                      ? Padding(
                          key: const ValueKey('ai_result'),
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withValues(
                                alpha: 0.28,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: colorScheme.primary.withValues(alpha: 0.14),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        Icons.auto_awesome_rounded,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'AI Analysis',
                                            style: textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          if (_aiConfidence != null)
                                            Text(
                                              '$_aiConfidence confidence',
                                              style: textTheme.bodySmall?.copyWith(
                                                color: colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (_aiPriority != null)
                                      _priorityChip(_aiPriority!),
                                  ],
                                ),
                                if (_aiReason != null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    _aiReason!,
                                    style: textTheme.bodyMedium?.copyWith(height: 1.35),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('ai_empty')),
                ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _sectionHeader(
                        icon: Icons.cloud_upload_rounded,
                        title: 'Attach Media',
                        subtitle: 'Optional photo or video evidence',
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: MediaPickerWidget(
                          onMediaSelected: (file, type) {
                            setState(() {
                              _selectedMedia = file;
                              _mediaType = type;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color:
                              (_currentPosition != null
                                      ? Colors.green
                                      : colorScheme.surfaceContainerHighest)
                                  .withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _currentPosition != null
                              ? Icons.location_on_rounded
                              : Icons.location_off_rounded,
                          color: _currentPosition != null
                              ? Colors.green.shade700
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Location',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _currentPosition != null
                                  ? '${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}'
                                  : 'Optional but recommended',
                              style: textTheme.bodySmall?.copyWith(
                                color: _currentPosition != null
                                    ? Colors.green.shade700
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: _currentPosition != null
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_isFetchingLocation)
                        const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      else if (_currentPosition == null)
                        IconButton.filledTonal(
                          onPressed: _fetchLocation,
                          icon: const Icon(Icons.my_location_rounded),
                          tooltip: 'Fetch location',
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportIntroCard extends StatelessWidget {
  const _ReportIntroCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.report_problem_outlined,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tell us what needs attention',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Add details, media, and location to help resolve it faster.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
