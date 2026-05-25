import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../entries/entries_repository.dart';
import '../../entries/models/foreign_entry_model.dart';
import '../models/event_model.dart';

Future<void> openForeignEntrySheet(
  BuildContext context,
  EventModel event,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => ForeignEntrySheet(event: event),
  );
}

class ForeignEntrySheet extends ConsumerStatefulWidget {
  final EventModel event;

  const ForeignEntrySheet({super.key, required this.event});

  @override
  ConsumerState<ForeignEntrySheet> createState() => _ForeignEntrySheetState();
}

class _ForeignEntrySheetState extends ConsumerState<ForeignEntrySheet> {
  final _formKey = GlobalKey<FormState>();

  final _uciController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _plateController = TextEditingController();
  final _transponder20Controller = TextEditingController();
  final _transponder24Controller = TextEditingController();

  DateTime? _dateOfBirth;
  String _gender = 'Muž';

  ForeignEntryInfo? _info;
  String? _lookupStatus; // null = idle, 'loading', 'found', 'not_found', 'error'
  String? _lookupError;

  bool _is20 = false;
  bool _isElite = false;
  bool _is24 = false;

  bool _submitting = false;
  Timer? _uciDebounce;

  // Riders registered so far in this session (name + class summary).
  final List<String> _registered = [];

  @override
  void initState() {
    super.initState();
    _uciController.addListener(_onUciChanged);
  }

  void _onUciChanged() {
    _uciDebounce?.cancel();
    final text = _uciController.text.trim();
    if (text.length < 8) {
      if (_lookupStatus != null) setState(() { _lookupStatus = null; _info = null; });
      return;
    }
    _uciDebounce = Timer(const Duration(milliseconds: 600), _lookupRider);
  }

  @override
  void dispose() {
    _uciDebounce?.cancel();
    _uciController.removeListener(_onUciChanged);
    _uciController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nationalityController.dispose();
    _plateController.dispose();
    _transponder20Controller.dispose();
    _transponder24Controller.dispose();
    super.dispose();
  }

  // ── Lookup ──────────────────────────────────────────────────────────────────

  Future<void> _lookupRider() async {
    final uciId = _uciController.text.trim();
    if (uciId.isEmpty) return;
    setState(() {
      _lookupStatus = 'loading';
      _lookupError = null;
      _info = null;
    });
    try {
      final info = await ref.read(entriesRepositoryProvider).fetchForeignEntryInfo(
            eventId: widget.event.id,
            uciId: uciId,
          );
      if (!mounted) return;
      _applyInfo(info);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lookupStatus = 'error';
        _lookupError = e.toString();
      });
    }
  }

  Future<void> _loadCategories() async {
    if (_dateOfBirth == null) return;
    final dob = DateFormat('yyyy-MM-dd').format(_dateOfBirth!);
    setState(() {
      _lookupStatus = 'loading';
      _lookupError = null;
    });
    try {
      final info = await ref.read(entriesRepositoryProvider).fetchForeignEntryInfo(
            eventId: widget.event.id,
            dob: dob,
            gender: _gender,
          );
      if (!mounted) return;
      setState(() {
        _info = info;
        _lookupStatus = 'categories_loaded';
        _resetCategorySelection(info.options);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lookupStatus = 'error';
        _lookupError = e.toString();
      });
    }
  }

  void _applyInfo(ForeignEntryInfo info) {
    final rider = info.rider;
    final found = rider?.found ?? false;
    setState(() {
      _info = info;
      _lookupStatus = found ? 'found' : 'not_found';
    });

    if (found && rider != null) {
      _firstNameController.text = rider.firstName;
      _lastNameController.text = rider.lastName;
      _nationalityController.text = rider.nationality;
      _plateController.text = rider.plate;
      _transponder20Controller.text = rider.transponder20;
      _transponder24Controller.text = rider.transponder24;
      if (rider.dateOfBirth != null) {
        _dateOfBirth = DateTime.tryParse(rider.dateOfBirth!);
      }
      _gender = rider.gender.isNotEmpty ? rider.gender : 'Muž';
      _resetCategorySelection(info.options);
    }
  }

  void _resetCategorySelection(ForeignEntryOptions? opts) {
    _is20 = opts?.is20.allowed ?? false;
    _isElite = false;
    _is24 = opts?.is24.allowed ?? false;
    // Default: only challenge if available
    if (_is20 && (opts?.isElite.allowed ?? false)) _isElite = false;
  }

  // ── Reset after successful entry ────────────────────────────────────────────

  void _resetForm() {
    _formKey.currentState?.reset();
    _uciController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    _nationalityController.clear();
    _plateController.clear();
    _transponder20Controller.clear();
    _transponder24Controller.clear();
    setState(() {
      _dateOfBirth = null;
      _gender = 'Muž';
      _info = null;
      _lookupStatus = null;
      _lookupError = null;
      _is20 = false;
      _isElite = false;
      _is24 = false;
    });
  }

  // ── Date picker ─────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 20),
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 3),
    );
    if (picked != null && picked != _dateOfBirth) {
      setState(() => _dateOfBirth = picked);
    }
  }

  // ── Submit ──────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.fillAllFields)),
      );
      return;
    }
    if (!_is20 && !_is24) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vyber alespoň jednu kategorii.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final result = await ref.read(entriesRepositoryProvider).enterForeignRider(
            eventId: widget.event.id,
            uciId: _uciController.text.trim(),
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            dateOfBirth: DateFormat('yyyy-MM-dd').format(_dateOfBirth!),
            gender: _gender,
            nationality: _nationalityController.text.trim(),
            plate: _plateController.text.trim(),
            transponder20: _transponder20Controller.text.trim(),
            transponder24: _transponder24Controller.text.trim(),
            is20: _is20,
            is24: _is24,
            isElite: _isElite,
          );

      ref.read(authProvider.notifier).refreshUser();

      if (mounted) {
        final classes = [
          if (result.class20 != null && result.class20!.isNotEmpty) result.class20!,
          if (result.class24 != null && result.class24!.isNotEmpty) result.class24!,
        ].join(' / ');
        final summary = classes.isNotEmpty
            ? '${result.riderFullName} ($classes)'
            : result.riderFullName;

        setState(() {
          _registered.add(summary);
        });
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final opts = _info?.options;
    final dobText = _dateOfBirth != null
        ? DateFormat('d. M. yyyy').format(_dateOfBirth!)
        : null;

    final totalFee = opts?.feeFor(
          is20: _is20,
          isElite: _isElite,
          is24: _is24,
        ) ??
        0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──────────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.foreignRiderEntry,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Already registered in this session ──────────────────────────
              if (_registered.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_outline,
                              size: 16, color: AppColors.success),
                          const SizedBox(width: 6),
                          Text(
                            context.l10n.registeredRiders,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge!
                                .copyWith(color: AppColors.success),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ..._registered.map(
                        (name) => Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              const SizedBox(width: 22),
                              const Icon(Icons.person_outline,
                                  size: 14, color: AppColors.success),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall!
                                      .copyWith(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  context.l10n.foreignRiderEntry,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
              ],

              // ── UCI ID ──────────────────────────────────────────────────────
              TextFormField(
                controller: _uciController,
                decoration: InputDecoration(
                  labelText: context.l10n.uciId,
                  hintText: '10012345678',
                  suffixIcon: _lookupStatus == 'loading'
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : _lookupStatus == 'found'
                          ? const Icon(Icons.check_circle_outline,
                              color: AppColors.success)
                          : null,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? context.l10n.fillAllFields
                    : null,
              ),

              // ── Lookup status banner ────────────────────────────────────────
              if (_lookupStatus == 'found')
                _StatusBanner(
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                  text: context.l10n.riderFound,
                ),
              if (_lookupStatus == 'not_found')
                _StatusBanner(
                  icon: Icons.info_outline,
                  color: colors.textMuted,
                  text: context.l10n.riderNotFound,
                ),
              if (_lookupStatus == 'error' && _lookupError != null)
                _StatusBanner(
                  icon: Icons.error_outline,
                  color: AppColors.error,
                  text: _lookupError!,
                ),

              const SizedBox(height: 12),

              // ── Name ────────────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _Field(
                      controller: _firstNameController,
                      label: context.l10n.firstName,
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Field(
                      controller: _lastNameController,
                      label: context.l10n.lastName,
                      required: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── DOB + Gender ────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: context.l10n.dateOfBirth,
                            suffixIcon: const Icon(Icons.calendar_today, size: 18),
                          ),
                          controller:
                              TextEditingController(text: dobText ?? ''),
                          validator: (_) => _dateOfBirth == null
                              ? context.l10n.fillAllFields
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration: InputDecoration(
                          labelText: context.l10n.gender),
                      items: const [
                        DropdownMenuItem(value: 'Muž', child: Text('Muž')),
                        DropdownMenuItem(value: 'Žena', child: Text('Žena')),
                        DropdownMenuItem(
                            value: 'Ostatní', child: Text('Ostatní')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _gender = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── Nationality + Plate ──────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _Field(
                      controller: _nationalityController,
                      label: context.l10n.nationality,
                      hint: 'AUT',
                      maxLength: 3,
                      caps: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Field(
                      controller: _plateController,
                      label: context.l10n.plateNumber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── Transponders ────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _Field(
                      controller: _transponder20Controller,
                      label: '${context.l10n.transponder} 20"',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Field(
                      controller: _transponder24Controller,
                      label: '${context.l10n.transponder} 24"',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),

              // ── Load categories button ───────────────────────────────────────
              if (_info == null || _info!.options == null) ...[
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _lookupStatus == 'loading' ? null : _loadCategories,
                  icon: const Icon(Icons.calculate_outlined, size: 18),
                  label: Text(context.l10n.calculateCategories),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textPrimary,
                    side: BorderSide(color: colors.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],

              // ── Categories ──────────────────────────────────────────────────
              if (opts != null) ...[
                const SizedBox(height: 14),
                Text(
                  'Kategorie',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                _CategoryTile(
                  label: context.l10n.challenge,
                  option: opts.is20,
                  selected: _is20 && !_isElite,
                  enabled: opts.is20.allowed,
                  onChanged: (v) {
                    if (v == true) {
                      setState(() { _is20 = true; _isElite = false; });
                    } else {
                      setState(() { _is20 = false; _isElite = false; });
                    }
                  },
                ),
                _CategoryTile(
                  label: context.l10n.championship,
                  option: opts.isElite,
                  selected: _is20 && _isElite,
                  enabled: opts.isElite.allowed,
                  onChanged: (v) {
                    if (v == true) {
                      setState(() { _is20 = true; _isElite = true; });
                    } else {
                      setState(() { _isElite = false; });
                    }
                  },
                ),
                _CategoryTile(
                  label: context.l10n.cruiser,
                  option: opts.is24,
                  selected: _is24,
                  enabled: opts.is24.allowed,
                  onChanged: (v) => setState(() => _is24 = v ?? false),
                ),
              ],

              // ── Total + Submit ────────────────────────────────────────────
              if (opts != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '${context.l10n.total}: $totalFee ${context.l10n.czk}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: (!_is20 && !_is24) || _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check),
                  label: Text(context.l10n.register),
                ),
              ],

              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _StatusBanner({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool required;
  final int? maxLength;
  final bool caps;
  final TextInputType? keyboardType;

  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.required = false,
    this.maxLength,
    this.caps = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
      ),
      maxLength: maxLength,
      textCapitalization:
          caps ? TextCapitalization.characters : TextCapitalization.none,
      keyboardType: keyboardType,
      validator: required
          ? (v) => (v == null || v.trim().isEmpty)
              ? context.l10n.fillAllFields
              : null
          : null,
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String label;
  final ForeignEntryOption option;
  final bool selected;
  final bool enabled;
  final ValueChanged<bool?> onChanged;

  const _CategoryTile({
    required this.label,
    required this.option,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = !enabled
        ? context.l10n.categoryNotAvailable
        : option.className != null
            ? '${option.className} — ${option.fee} ${context.l10n.czk}'
            : '${option.fee} ${context.l10n.czk}';

    return CheckboxListTile(
      value: selected,
      onChanged: enabled ? onChanged : null,
      title: Text(label),
      subtitle: Text(subtitle),
      contentPadding: EdgeInsets.zero,
    );
  }
}
