import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/common/widgets/code_picker_widget.dart';

Color authMuted(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFFB8C4CE)
    : const Color(0xFF596A75);
Color authBorder(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF46535C)
    : const Color(0xFFCFDAD4);

class _AuthViewport extends InheritedWidget {
  final bool compact;
  const _AuthViewport({required this.compact, required super.child});
  @override
  bool updateShouldNotify(_AuthViewport oldWidget) =>
      compact != oldWidget.compact;
}

bool authCompact(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<_AuthViewport>()?.compact ??
    (MediaQuery.viewInsetsOf(context).bottom > 0 ||
        MediaQuery.sizeOf(context).height < 600);

/// Scrollable, bounded content keeps the complete form reachable above a keyboard.
class MiliAuthLayout extends StatelessWidget {
  final String logoAsset;
  final List<Widget> children;
  const MiliAuthLayout({
    super.key,
    required this.logoAsset,
    required this.children,
  });
  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final family = Get.locale?.languageCode == 'ka'
        ? 'MiliAuthGeorgian'
        : base.textTheme.bodyMedium?.fontFamily;
    return Theme(
      data: base.copyWith(textTheme: base.textTheme.apply(fontFamily: family)),
      child: DefaultTextStyle.merge(
        style: TextStyle(fontFamily: family),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = authCompact(context) || constraints.maxHeight < 500;
            return _AuthViewport(
              compact: compact,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(24, compact ? 8 : 28, 24, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!compact) ...[
                            Row(
                              children: [
                                ExcludeSemantics(
                                  child: Image.asset(
                                    logoAsset,
                                    height: 48,
                                    width: 48,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'MILI',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1,
                                            ),
                                      ),
                                      Text(
                                        'auth_ui_role'.tr,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: authMuted(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                          ],
                          ...children,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class MiliAuthIntro extends StatelessWidget {
  final String title;
  final String subtitle;
  const MiliAuthIntro({super.key, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: authCompact(context) ? 16 : 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
        if (!authCompact(context)) ...[
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              height: 1.55,
              color: authMuted(context),
            ),
          ),
        ],
      ],
    ),
  );
}

class MiliAuthField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;
  final TextInputType inputType;
  final TextInputAction inputAction;
  final bool isPassword;
  final bool isPhone;
  final bool enabled;
  final String? countryDialCode;
  final ValueChanged<CountryCode>? onCountryChanged;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmit;
  final String? Function(String?)? validator;
  final List<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  const MiliAuthField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.focusNode,
    this.nextFocus,
    this.inputType = TextInputType.text,
    this.inputAction = TextInputAction.next,
    this.isPassword = false,
    this.isPhone = false,
    this.enabled = true,
    this.countryDialCode,
    this.onCountryChanged,
    this.onChanged,
    this.onSubmit,
    this.validator,
    this.autofillHints,
    this.inputFormatters,
  });
  @override
  State<MiliAuthField> createState() => _MiliAuthFieldState();
}

class _MiliAuthFieldState extends State<MiliAuthField> {
  bool _obscure = true;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: authBorder(context)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 2, bottom: 8),
          child: Text(
            widget.label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        Semantics(
          label: widget.label,
          child: TextFormField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            enabled: widget.enabled,
            keyboardType: widget.inputType,
            textInputAction: widget.inputAction,
            obscureText: widget.isPassword && _obscure,
            autocorrect: false,
            enableSuggestions: !widget.isPassword,
            textCapitalization: TextCapitalization.none,
            autofillHints:
                widget.autofillHints ??
                (widget.isPassword
                    ? const [AutofillHints.password]
                    : const [AutofillHints.username]),
            inputFormatters: widget.inputFormatters,
            validator: widget.validator,
            onChanged: widget.onChanged,
            scrollPadding: const EdgeInsets.only(bottom: 100, top: 24),
            style: TextStyle(
              fontSize: 16,
              height: 1.4,
              color: theme.textTheme.bodyLarge?.color,
            ),
            onFieldSubmitted: (value) {
              if (widget.nextFocus != null) {
                widget.nextFocus!.requestFocus();
              } else {
                widget.onSubmit?.call(value);
              }
            },
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(fontSize: 15, color: authMuted(context)),
              label: null,
              filled: true,
              fillColor: theme.cardColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 17,
              ),
              border: border,
              enabledBorder: border,
              disabledBorder: border,
              focusedBorder: border.copyWith(
                borderSide: BorderSide(color: theme.primaryColor, width: 1.6),
              ),
              errorBorder: border.copyWith(
                borderSide: BorderSide(color: theme.colorScheme.error),
              ),
              focusedErrorBorder: border.copyWith(
                borderSide: BorderSide(
                  color: theme.colorScheme.error,
                  width: 1.6,
                ),
              ),
              errorMaxLines: 3,
              prefixIcon: (widget.isPhone || widget.countryDialCode != null)
                  ? Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: 8,
                        end: 8,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 90,
                          maxWidth: 124,
                        ),
                        child: CodePickerWidget(
                          initialSelection: widget.countryDialCode ?? 'GE',
                          favorite: [widget.countryDialCode ?? 'GE'],
                          onChanged: widget.onCountryChanged,
                          flagWidth: 22,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          textStyle: TextStyle(
                            fontSize: 14,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                          dialogBackgroundColor: theme.cardColor,
                          backgroundColor: theme.cardColor,
                        ),
                      ),
                    )
                  : null,
              suffixIcon: widget.isPassword
                  ? IconButton(
                      tooltip:
                          (_obscure
                                  ? 'auth_ui_show_password'
                                  : 'auth_ui_hide_password')
                              .tr,
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: authMuted(context),
                        size: 21,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

class MiliAuthOptions extends StatelessWidget {
  final bool remember;
  final VoidCallback onRemember;
  final VoidCallback? onForgot;
  const MiliAuthOptions({
    super.key,
    required this.remember,
    required this.onRemember,
    this.onForgot,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        MergeSemantics(
          child: InkWell(
            onTap: onRemember,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: remember,
                    onChanged: (_) => onRemember(),
                    activeColor: Theme.of(context).primaryColor,
                    side: BorderSide(color: authMuted(context), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      'remember_me'.tr,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (onForgot != null)
          TextButton(
            onPressed: onForgot,
            child: Text(
              '${'forgot_password'.tr}?',
              style: const TextStyle(fontSize: 13),
              textAlign: TextAlign.start,
            ),
          ),
      ],
    ),
  );
}

class MiliAuthSubmit extends StatelessWidget {
  final bool loading;
  final String label;
  final VoidCallback onPressed;
  const MiliAuthSubmit({
    super.key,
    required this.loading,
    required this.label,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: loading
          ? Semantics(
              liveRegion: true,
              label: 'loading'.tr,
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            )
          : Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
    ),
  );
}

class MiliAuthSecondary extends StatelessWidget {
  final String label;
  final String? description;
  final IconData icon;
  final VoidCallback? onPressed;
  const MiliAuthSecondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.description,
    this.icon = Icons.person_add_alt_outlined,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Column(
      children: [
        if (description != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              description!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: authMuted(context),
              ),
            ),
          ),
        TextButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label, textAlign: TextAlign.center),
        ),
      ],
    ),
  );
}
