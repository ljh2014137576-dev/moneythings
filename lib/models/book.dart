/// 账本模型
library;

class Book {
  const Book({
    required this.id,
    required this.name,
    this.iconKey = 'menu_book',
  });

  final String id;
  final String name;
  final String iconKey;

  Book copyWith({String? name, String? iconKey}) => Book(
        id: id,
        name: name ?? this.name,
        iconKey: iconKey ?? this.iconKey,
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'iconKey': iconKey};

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        id: json['id'] as String,
        name: json['name'] as String,
        iconKey: (json['iconKey'] as String?) ?? 'menu_book',
      );
}

/// 默认账本（所有历史流水归属）
const Book kDefaultBook = Book(id: 'default', name: '默认账本');

/// 账本 id 是否内置
bool isBuiltInBook(String id) => id == kDefaultBook.id;
