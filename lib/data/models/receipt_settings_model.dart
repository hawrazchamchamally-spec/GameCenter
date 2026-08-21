/// Model representing customizable receipt header and footer information
class ReceiptSettingsModel {
  final String centerName;
  final String address;
  final String phoneNumber;
  final String footerNote;

  const ReceiptSettingsModel({
    this.centerName = 'مركز الألعاب | GAME LOUNGE',
    this.address = 'بغداد - المنصور - شارع 14 رمضان',
    this.phoneNumber = '07701234567 / 07801234567',
    this.footerNote = 'شكراً لزيارتكم! نتمنى لكم وقتاً ممتعاً',
  });

  ReceiptSettingsModel copyWith({
    String? centerName,
    String? address,
    String? phoneNumber,
    String? footerNote,
  }) {
    return ReceiptSettingsModel(
      centerName: centerName ?? this.centerName,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      footerNote: footerNote ?? this.footerNote,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'centerName': centerName,
      'address': address,
      'phoneNumber': phoneNumber,
      'footerNote': footerNote,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory ReceiptSettingsModel.fromMap(Map<String, dynamic> map) {
    return ReceiptSettingsModel(
      centerName: map['centerName']?.toString() ?? 'مركز الألعاب | GAME LOUNGE',
      address: map['address']?.toString() ?? 'بغداد - المنصور - شارع 14 رمضان',
      phoneNumber: map['phoneNumber']?.toString() ?? '07701234567 / 07801234567',
      footerNote: map['footerNote']?.toString() ?? 'شكراً لزيارتكم! نتمنى لكم وقتاً ممتعاً',
    );
  }

  factory ReceiptSettingsModel.fromJson(Map<String, dynamic> json) =>
      ReceiptSettingsModel.fromMap(json);
}
