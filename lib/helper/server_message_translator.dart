class ServerMessageTranslator {
  static final Map<String, String> _messages = <String, String>{
    'order cancelled succesfully': 'შეკვეთა წარმატებით გაუქმდა.',
    'order cancelled successfully': 'შეკვეთა წარმატებით გაუქმდა.',
    'order canceled successfully': 'შეკვეთა წარმატებით გაუქმდა.',
    'successfully added': 'წარმატებით დაემატა.',
    'successfully removed': 'წარმატებით წაიშალა.',
    'address deleted successfully': 'მისამართი წარმატებით წაიშალა.',
    'item already exists': 'ნივთი უკვე დამატებულია.',
    'cart item remove successfully': 'ნივთი კალათიდან წარმატებით წაიშალა.',
    'updated successfully': 'წარმატებით განახლდა.',
    'status updated': 'სტატუსი განახლდა.',
    'status updated successfully': 'სტატუსი წარმატებით განახლდა.',
    'order status updated': 'შეკვეთის სტატუსი განახლდა.',
    'order status updated successfully':
        'შეკვეთის სტატუსი წარმატებით განახლდა.',
    'order accepted successfully': 'შეკვეთა წარმატებით მიიღეთ.',
    'order picked up successfully': 'შეკვეთა წარმატებით აიღეთ.',
    'payment info updated': 'გადახდის ინფორმაცია განახლდა.',
    'request sent successfully': 'მოთხოვნა წარმატებით გაიგზავნა.',
    'add successfully': 'წარმატებით დაემატა.',
    'update successfully': 'წარმატებით განახლდა.',
    'method delete successfully': 'მეთოდი წარმატებით წაიშალა.',
    'set default method successful': 'ნაგულისხმევი მეთოდი წარმატებით შეინახა.',
  };

  static String translate(String? message) {
    if (message == null || message.trim().isEmpty) {
      return '';
    }

    final String normalized = _normalize(message);
    final String? exact = _messages[normalized];

    if (exact != null) {
      return exact;
    }

    return message;
  }

  static String _normalize(String message) {
    return message
        .trim()
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'[.!]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();
  }
}
