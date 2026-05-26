import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_colors.dart';

// API values are fixed Czech strings required by the backend
const _genderMale = 'Muž';
const _genderFemale = 'Žena';
const _genderOther = 'Ostatní';

class PlateRequestScreen extends ConsumerStatefulWidget {
  const PlateRequestScreen({super.key});

  @override
  ConsumerState<PlateRequestScreen> createState() => _PlateRequestScreenState();
}

class _PlateRequestScreenState extends ConsumerState<PlateRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  final _uciController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  DateTime? _dateOfBirth;
  String _gender = 'Muž';
  bool _is20 = true;
  bool _is24 = false;
  bool _isElite = false;

  // Lookup state
  String? _lookupStatus; // null | 'loading' | 'found' | 'not_found' | 'error'
  String? _lookupError;
  Timer? _uciDebounce;

  // Data from API
  List<String> _freePlates = [];
  String? _selectedPlate;
  List<Map<String, dynamic>> _clubs = [];
  int? _selectedClubId;
  String? _selectedClubName;

  bool _loadingPlates = false;
  bool _loadingClubs = false;
  bool _submitting = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _uciController.addListener(_onUciChanged);
    _loadFreePlates();
    _loadClubs();
  }

  @override
  void dispose() {
    _uciDebounce?.cancel();
    _uciController.removeListener(_onUciChanged);
    _uciController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  // ── Data loading ─────────────────────────────────────────────────────────────

  Future<void> _loadFreePlates() async {
    setState(() => _loadingPlates = true);
    try {
      final dio = ref.read(publicDioProvider);
      final resp = await dio.get(ApiConstants.plateRequestFreePlates);
      final plates = List<String>.from(resp.data['free_plates'] as List);
      setState(() {
        _freePlates = plates;
        if (plates.isNotEmpty) _selectedPlate = plates.first;
      });
    } catch (_) {
      // Non-fatal — user will see empty dropdown
    } finally {
      if (mounted) setState(() => _loadingPlates = false);
    }
  }

  Future<void> _loadClubs() async {
    setState(() => _loadingClubs = true);
    try {
      final dio = ref.read(publicDioProvider);
      final resp = await dio.get(ApiConstants.clubs);
      final data = resp.data;
      final raw = data is List ? data : (data['results'] as List? ?? []);
      final clubs = raw.cast<Map<String, dynamic>>();
      setState(() => _clubs = clubs);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingClubs = false);
    }
  }

  // ── UCI ID lookup ─────────────────────────────────────────────────────────────

  void _onUciChanged() {
    _uciDebounce?.cancel();
    final text = _uciController.text.trim();
    if (text.length < 11) {
      if (_lookupStatus != null) {
        setState(() {
          _lookupStatus = null;
          _lookupError = null;
        });
      }
      return;
    }
    _uciDebounce = Timer(const Duration(milliseconds: 700), _lookupRider);
  }

  Future<void> _lookupRider() async {
    final uciId = _uciController.text.trim();
    if (uciId.length != 11) return;
    setState(() {
      _lookupStatus = 'loading';
      _lookupError = null;
    });
    try {
      final dio = ref.read(publicDioProvider);
      final resp = await dio.get(
        ApiConstants.plateRequestLookup,
        queryParameters: {'uci_id': uciId},
      );
      if (!mounted) return;
      final d = resp.data as Map<String, dynamic>;
      _firstNameController.text = d['first_name'] as String? ?? '';
      _lastNameController.text = d['last_name'] as String? ?? '';
      if (d['date_of_birth'] != null) {
        _dateOfBirth = DateTime.tryParse(d['date_of_birth'] as String);
        if (_dateOfBirth != null) _dobController.text = DateFormat('d. M. yyyy').format(_dateOfBirth!);
      }
      _gender = d['gender'] as String? ?? 'Muž';
      setState(() => _lookupStatus = 'found');
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = (e.response?.data as Map<String, dynamic>?)?['error'] as String?;
      setState(() {
        _lookupStatus = e.response?.statusCode == 404 ? 'not_found' : 'error';
        _lookupError = msg ?? e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lookupStatus = 'error';
        _lookupError = e.toString();
      });
    }
  }

  // ── Date picker ───────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 20),
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 3),
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
      _dobController.text = DateFormat('d. M. yyyy').format(picked);
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_dateOfBirth == null) {
      _showError(context.l10n.fillAllFields);
      return;
    }

    if (!_is20 && !_is24) {
      _showError(context.l10n.bikeCategories);
      return;
    }
    if (_selectedPlate == null) {
      _showError(context.l10n.selectPlate);
      return;
    }
    if (_selectedClubId == null) {
      _showError(context.l10n.selectClub);
      return;
    }

    setState(() => _submitting = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post(ApiConstants.plateRequest, data: {
        'uci_id': _uciController.text.trim(),
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'date_of_birth': DateFormat('yyyy-MM-dd').format(_dateOfBirth!),
        'gender': _gender,
        'plate': _selectedPlate,
        'club_id': _selectedClubId,
        'is_20': _is20,
        'is_24': _is24,
        'is_elite': _isElite,
        'emergency_contact': _emergencyContactController.text.trim(),
        'emergency_phone': _emergencyPhoneController.text.trim(),
      });
      if (mounted) setState(() => _submitted = true);
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = (e.response?.data as Map<String, dynamic>?)?['error'] as String?;
      _showError(msg ?? e.message ?? context.l10n.submitError);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_submitted) return _SuccessView(onBack: () => Navigator.pop(context));

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.requestPlateNumber)),
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                children: [
                  // Intro
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      context.l10n.plateRequestIntro,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: colors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Section: Identification ──
                  _FormSection(
                    title: context.l10n.uciId,
                    children: [
                      TextFormField(
                        controller: _uciController,
                        decoration: InputDecoration(
                          hintText: '10012345678',
                          prefixIcon: const Icon(Icons.fingerprint, size: 20),
                          suffixIcon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _lookupStatus == 'loading'
                                ? const Padding(
                                    key: ValueKey('loading_spinner'),
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                    ),
                                  )
                                : const SizedBox.shrink(key: ValueKey('empty_suffix')),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
                        validator: (v) => (v == null || v.trim().length != 11) ? context.l10n.uciIdMustBe11Digits : null,
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SizeTransition(sizeFactor: animation, axisAlignment: -1, child: child),
                          );
                        },
                        child: (_lookupStatus != null && _lookupStatus != 'loading')
                            ? Padding(
                                key: ValueKey('banner_${_lookupStatus}_${_lookupError ?? ''}'),
                                padding: const EdgeInsets.only(top: 12),
                                child: _StatusBanner(
                                  status: _lookupStatus!,
                                  error: _lookupError,
                                  textFound: context.l10n.riderFound,
                                  textNotFound: context.l10n.riderNotFound,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),

                  _FormSection(
                    title: '${context.l10n.firstName} / ${context.l10n.lastName}',
                    children: [
                      Row(children: [
                        Expanded(child: _Field(controller: _firstNameController, label: context.l10n.firstName, required: true)),
                        const SizedBox(width: 10),
                        Expanded(child: _Field(controller: _lastNameController, label: context.l10n.lastName, required: true)),
                      ]),
                      const SizedBox(height: 16),
                      TextFormField(
                        readOnly: true,
                        onTap: _pickDate,
                        decoration: InputDecoration(
                          labelText: context.l10n.dateOfBirth,
                          suffixIcon: const Icon(Icons.calendar_today, size: 18),
                          filled: true,
                          fillColor: Theme.of(context).dividerColor.withValues(alpha: 0.02),
                        ),
                        controller: _dobController,
                        validator: (_) => _dateOfBirth == null ? context.l10n.fillAllFields : null,
                      ),
                      const SizedBox(height: 16),
                      _SectionLabel(context.l10n.gender),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<String>(
                          segments: [
                            ButtonSegment(value: _genderMale, label: Text(context.l10n.genderMale)),
                            ButtonSegment(value: _genderFemale, label: Text(context.l10n.genderFemale)),
                            ButtonSegment(value: _genderOther, label: Text(context.l10n.genderOther)),
                          ],
                          selected: {_gender},
                          onSelectionChanged: (val) => setState(() => _gender = val.first),
                          showSelectedIcon: false,
                        ),
                      ),
                    ],
                  ),

                  // ── Section: Bike categories ──
                  _FormSection(
                    title: context.l10n.bikeCategories,
                    children: [
                      CheckboxListTile(
                        value: _is20 && !_isElite,
                        contentPadding: EdgeInsets.zero,
                        title: Text(context.l10n.challenge),
                        onChanged: (v) => setState(() { _is20 = v ?? false; _isElite = false; }),
                      ),
                      CheckboxListTile(
                        value: _is20 && _isElite,
                        contentPadding: EdgeInsets.zero,
                        title: Text(context.l10n.championship),
                        onChanged: (v) => setState(() { _is20 = v ?? false; _isElite = v ?? false; }),
                      ),
                      CheckboxListTile(
                        value: _is24,
                        contentPadding: EdgeInsets.zero,
                        title: Text(context.l10n.cruiser),
                        onChanged: (v) => setState(() => _is24 = v ?? false),
                      ),
                    ],
                  ),

                  // ── Section: Selections ──
                  _FormSection(
                    title: '${context.l10n.selectClub} & ${context.l10n.selectPlate}',
                    children: [
                      if (_loadingClubs)
                        const _SkeletonLoader()
                      else
                        DropdownButtonFormField<int>(
                          value: _selectedClubId,
                          decoration: InputDecoration(labelText: context.l10n.selectClub),
                          isExpanded: true,
                          items: _clubs.map((c) => DropdownMenuItem<int>(value: c['id'] as int, child: Text(c['team_name'] as String? ?? ''))).toList(),
                          onChanged: (v) => setState(() {
                            _selectedClubId = v;
                            _selectedClubName = _clubs.firstWhere((c) => c['id'] == v)['team_name'] as String?;
                          }),
                          validator: (v) => v == null ? context.l10n.fillAllFields : null,
                        ),
                      const SizedBox(height: 16),
                      if (_loadingPlates)
                        const _SkeletonLoader()
                      else
                        _freePlates.isEmpty
                            ? Text(context.l10n.noFreePlates, style: TextStyle(color: colors.textMuted))
                            : DropdownButtonFormField<String>(
                                  value: _selectedPlate,
                                  decoration: InputDecoration(labelText: context.l10n.plateNumber),
                                  isExpanded: true,
                                  items: _freePlates.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                                  onChanged: (v) => setState(() => _selectedPlate = v),
                                  validator: (v) => v == null ? context.l10n.fillAllFields : null,
                                ),
                    ],
                  ),

                  // ── Section: Emergency ──
                  _FormSection(
                    title: '${context.l10n.emergencyContact} / ${context.l10n.emergencyPhone}',
                    children: [
                      _Field(controller: _emergencyContactController, label: context.l10n.emergencyContact, required: true),
                      const SizedBox(height: 16),
                      _Field(
                        controller: _emergencyPhoneController,
                        label: context.l10n.emergencyPhone,
                        required: true,
                        keyboardType: TextInputType.phone,
                        validator: (v) => (v == null || v.trim().length < 9) ? context.l10n.phone : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Sticky Submit Button
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_outlined),
                label: Text(context.l10n.requestPlateNumber),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Success screen ────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  final VoidCallback onBack;
  const _SuccessView({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.requestPlateNumber)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
              ),
              const SizedBox(height: 24),
              Text(
                context.l10n.plateRequestSuccess,
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.plateRequestPendingApproval,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: context.colors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: onBack,
                child: Text(context.l10n.profile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _FormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _FormSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(title),
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: context.colors.textMuted,
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String status;
  final String? error;
  final String textFound;
  final String textNotFound;

  const _StatusBanner({
    required this.status,
    this.error,
    required this.textFound,
    required this.textNotFound,
  });

  @override
  Widget build(BuildContext context) {
    final color = status == 'found'
        ? AppColors.success
        : status == 'not_found'
            ? context.colors.textMuted
            : AppColors.error;

    final icon = status == 'found'
        ? Icons.check_circle
        : status == 'not_found'
            ? Icons.info
            : Icons.error;

    final text = status == 'found' ? textFound : status == 'not_found' ? textNotFound : (error ?? 'Error');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13))),
      ]),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool required;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    this.required = false,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).dividerColor.withValues(alpha: 0.02),
      ),
      keyboardType: keyboardType,
      validator: validator ?? (required
          ? (v) => (v == null || v.trim().isEmpty) ? context.l10n.fillAllFields : null
          : null),
    );
  }
}

class _SkeletonLoader extends StatelessWidget {
  const _SkeletonLoader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
