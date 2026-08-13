/// Autor de un mensaje del chat de onboarding.
///
/// El tipo decide cómo se dibuja el mensaje: Lumo a la izquierda
/// con su marca, el usuario a la derecha con la burbuja primaria.
enum MessageType { lumo, user }

/// Mensaje individual del onboarding conversacional.
class ChatMessage {
  final MessageType type;
  final String text;

  const ChatMessage({required this.type, required this.text});

  const ChatMessage.user(String text)
    : this(type: MessageType.user, text: text);

  const ChatMessage.lumo(String text)
    : this(type: MessageType.lumo, text: text);
}
