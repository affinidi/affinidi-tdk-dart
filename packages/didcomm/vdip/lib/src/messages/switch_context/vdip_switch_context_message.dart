import 'package:affinidi_tdk_didcomm_mediator_client/affinidi_tdk_didcomm_mediator_client.dart';
import 'package:json_annotation/json_annotation.dart';

part 'vdip_switch_context_message.g.dart';

/// DIDComm message for switching context.
class VdipSwitchContextMessage extends PlainTextMessage {
  /// Message type URI for switching context.
  static final Uri messageType = Uri.parse(
    'https://affinidi.com/didcomm/protocols/vdip/1.0/switch-context',
  );

  /// Creates a new [VdipSwitchContextMessage].
  VdipSwitchContextMessage({
    required super.id,
    super.from,
    super.to,
    super.createdTime,
    super.expiresTime,
    super.threadId,
    super.body = const {},
    super.attachments,
  }) : super(type: messageType);

  /// Strongly typed view of the switch context body.
  VdipSwitchContextBody get switchContext {
    final payload = body;

    if (payload == null) {
      throw StateError('Message body is missing.');
    }

    return VdipSwitchContextBody.fromJson(Map<String, dynamic>.from(payload));
  }
}

/// Body payload for the switch context message.
///
/// This payload is sent inside [VdipSwitchContextMessage.body]. It contains the
/// issuer base URL to switch to and a nonce for replay protection.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class VdipSwitchContextBody {
  /// Creates a [VdipSwitchContextBody].
  VdipSwitchContextBody({required this.baseIssuerUrl, required this.nonce});

  /// Base issuer URL the agent should switch its context to.
  @JsonKey(name: 'base_issuer_url')
  final String baseIssuerUrl;

  /// Random nonce used to correlate the request and mitigate replay.
  final String nonce;

  /// Creates a [VdipSwitchContextBody] from JSON.
  factory VdipSwitchContextBody.fromJson(Map<String, dynamic> json) =>
      _$VdipSwitchContextBodyFromJson(json);

  /// Converts this payload to JSON.
  Map<String, dynamic> toJson() => _$VdipSwitchContextBodyToJson(this);
}
