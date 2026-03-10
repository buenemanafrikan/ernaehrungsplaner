class ShoppingItem {
  final String id;
  final String text;
  final bool done;

  const ShoppingItem({
    required this.id,
    required this.text,
    required this.done,
  });

  ShoppingItem copyWith({String? id, String? text, bool? done}) => ShoppingItem(
        id: id ?? this.id,
        text: text ?? this.text,
        done: done ?? this.done,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "text": text,
        "done": done,
      };

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
        id: json["id"] as String,
        text: (json["text"] as String? ?? "").trim(),
        done: (json["done"] as bool?) ?? false,
      );
}