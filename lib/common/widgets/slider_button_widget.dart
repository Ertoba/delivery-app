import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:vibration/vibration.dart';

class SliderButton extends StatefulWidget {
  ///To make button more customizable add your child widget
  final Widget? child;

  ///Sets the radius of corners of a button.
  final double radius;

  ///Use it to define a height and width of widget.
  final double height;
  final double width;
  final double buttonSize;

  ///Use it to define a color of widget.
  final Color backgroundColor;
  final Color baseColor;
  final Color highlightedColor;
  final Color buttonColor;

  ///Change it to gave a label on a widget of your choice.
  final Text? label;

  ///Gives a alignment to a slidder icon.
  final Alignment alignLabel;
  final BoxShadow boxShadow;
  final Widget icon;
  final FutureOr<dynamic> Function() action;

  ///Make it false if you want to deactivate the shimmer effect.
  final bool shimmer;

  ///Make it false if you want maintain the widget in the tree.
  final bool dismissible;

  final bool vibrationFlag;

  ///The offset threshold the item has to be dragged in order to be considered
  ///dismissed e.g. if it is 0.4, then the item has to be dragged
  /// at least 40% towards one direction to be considered dismissed
  final double dismissThresholds;

  final bool disable;
  final bool isLtr;
  const SliderButton({
    super.key,
    required this.action,
    this.radius = 100,
    this.boxShadow = const BoxShadow(color: Colors.black, blurRadius: 4),
    this.child,
    this.isLtr = true,
    this.vibrationFlag = true,
    this.shimmer = true,
    this.height = 70,
    this.buttonSize = 60,
    this.width = 250,
    this.alignLabel = const Alignment(0.0, 0),
    this.backgroundColor = const Color(0xffe0e0e0),
    this.baseColor = Colors.black87,
    this.buttonColor = Colors.white,
    this.highlightedColor = Colors.white,
    this.label,
    this.icon = const Icon(
      Icons.power_settings_new,
      color: Colors.red,
      size: 30.0,
      semanticLabel: 'Text to announce in accessibility modes',
    ),
    this.dismissible = true,
    this.dismissThresholds = 1.0,
    this.disable = false,
  }) : assert(buttonSize <= height);

  @override
  SliderButtonState createState() => SliderButtonState();
}

class SliderButtonState extends State<SliderButton> {
  bool? flag;
  Widget? _child;
  bool _isSubmitting = false;

  bool get _isDisabled => widget.disable || _isSubmitting;

  @override
  void initState() {
    super.initState();
    flag = true;
    _child = widget.child;
  }

  @override
  Widget build(BuildContext context) {
    return _isSubmitting
        ? _control()
        : flag == true
        ? _control()
        : widget.dismissible == true
        ? Container()
        : Container(child: _control());
  }

  Widget _control() => Container(
    height: widget.height,
    width: widget.width,
    decoration: BoxDecoration(
      color: _isDisabled
          ? Colors.grey.shade700
          : Get.isDarkMode
          ? Colors.white12
          : widget.backgroundColor,
      borderRadius: BorderRadius.circular(widget.radius),
    ),
    alignment: Alignment.centerLeft,
    child: Stack(
      alignment: Alignment.centerLeft,
      children: <Widget>[
        Container(
          alignment: widget.alignLabel,
          padding: EdgeInsets.symmetric(horizontal: widget.buttonSize + 12),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _isSubmitting
                ? Row(
                    key: const ValueKey('slider_processing'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: widget.highlightedColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'processing'.tr,
                        style: TextStyle(color: widget.highlightedColor),
                      ),
                    ],
                  )
                : FittedBox(
                    key: const ValueKey('slider_idle'),
                    fit: BoxFit.scaleDown,
                    child: widget.shimmer && !widget.disable
                        ? Shimmer(
                            color: widget.highlightedColor,
                            child: widget.label!,
                          )
                        : widget.label,
                  ),
          ),
        ),

        _isDisabled
            ? Tooltip(
                verticalOffset: 50,
                message: 'Button is disabled',
                child: Container(
                  width: widget.width - (widget.height),
                  height: widget.height,
                  alignment: widget.isLtr
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  padding: EdgeInsets.only(
                    left: (widget.height - widget.buttonSize) / 2,
                  ),
                  child:
                      _child ??
                      Container(
                        height: widget.buttonSize,
                        width: widget.buttonSize,
                        decoration: BoxDecoration(
                          boxShadow: [widget.boxShadow],
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(widget.radius),
                        ),
                        child: Center(
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : widget.icon,
                        ),
                      ),
                ),
              )
            : Dismissible(
                key: const Key("cancel"),
                direction: DismissDirection.startToEnd,
                dismissThresholds: {
                  DismissDirection.startToEnd: widget.dismissThresholds,
                },

                ///gives direction of swipping in argument.
                onDismissed: (dir) async {
                  setState(() {
                    _isSubmitting = true;
                    if (widget.dismissible) {
                      flag = false;
                    } else {
                      flag = !flag!;
                    }
                  });

                  try {
                    await Future.sync(widget.action);
                    if (widget.vibrationFlag &&
                        (await Vibration.hasVibrator())) {
                      Vibration.vibrate(duration: 200);
                    }
                  } catch (error) {
                    if (kDebugMode) {
                      debugPrint('Slider action failed: $error');
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isSubmitting = false;
                      });
                    }
                  }
                },
                child: Container(
                  width: widget.width - (widget.height),
                  height: widget.height,
                  alignment: widget.isLtr
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  padding: EdgeInsets.only(
                    left: (widget.height - widget.buttonSize) / 2,
                  ),
                  child:
                      _child ??
                      Container(
                        height: widget.buttonSize,
                        width: widget.buttonSize,
                        decoration: BoxDecoration(
                          boxShadow: [widget.boxShadow],
                          color: widget.buttonColor,
                          borderRadius: BorderRadius.circular(widget.radius),
                        ),
                        child: Center(child: widget.icon),
                      ),
                ),
              ),
        const SizedBox.expand(),
      ],
    ),
  );
}
