import 'package:flutter/material.dart';

import 'package:fl_nodes/fl_nodes.dart';

import 'builders.dart';

class DefaultFieldWidget extends StatelessWidget {
  // ignore: use_key_in_widget_constructors (we override super.key)
  const DefaultFieldWidget({
    required this.field,
    required this.node,
    FlNodeFieldBuilder? fieldBuilder,
    required this.controller,
  }) : fieldBuilder = fieldBuilder ?? _defaultFieldBuilder;

  final FieldInstance field;
  final NodeInstance node;

  final FlNodeFieldBuilder fieldBuilder;
  final FlNodeEditorController controller;

  @override
  Key get key => field.key;

  @override
  Widget build(BuildContext context) {
    // Wrap the content with a GestureDetector to ensure tap handling.
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        // Since we use [onTapDown] (and not [onTap]), this callback will
        // still be called, even if the child ends up handling the tap
        onTapDown: (details) {
          if (field.prototype.onVisualizerTap != null) {
            field.prototype.onVisualizerTap!(field.data, _onSetData);
          } else {
            _showFieldEditorOverlay(
              context,
              details.globalPosition,
            );
          }
        },
        child: fieldBuilder(context, field, node.builtStyle),
      ),
    );
  }

  static Widget _defaultFieldBuilder(
    BuildContext _,
    FieldInstance field,
    FlNodeStyle nodeStyle,
  ) =>
      Container(
        padding: field.prototype.style.padding,
        decoration: field.prototype.style.decoration,
        child: Row(
          children: [
            Flexible(
              child: Text(
                field.prototype.displayName,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: field.prototype.visualizerBuilder(field.data)),
          ],
        ),
      );

  void _onSetData(dynamic data) => controller.setFieldData(
        node.id,
        field.prototype.idName,
        data: data,
        eventType: FieldEventType.submit,
      );

  void _onEditorSetData(dynamic data, {required FieldEventType eventType}) =>
      _onSetData(data);

  void _showFieldEditorOverlay(
    BuildContext context,
    Offset position,
  ) {
    assert(field.prototype.editorBuilder != null);

    final editorOverlay = Overlay.of(context);

    late OverlayEntry overlayEntry;
    void dismissEditor() => overlayEntry.remove();

    // we create a little popup at the position of the click,
    // and overlay it on top of the editor/page
    overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // detect any click outside the editor and dismiss it
            // (because onTap won't be called if [editorBuilder] catches it)
            GestureDetector(
              onTap: dismissEditor,
              child: Container(color: Colors.transparent),
            ),
            // position the actual editor widget at the position of the click
            Positioned(
              left: position.dx,
              top: position.dy,
              child: Material(
                child: field.prototype.editorBuilder!(
                  context,
                  dismissEditor,
                  field.data,
                  _onEditorSetData,
                ),
              ),
            ),
          ],
        );
      },
    );

    editorOverlay.insert(overlayEntry);
  }
}
