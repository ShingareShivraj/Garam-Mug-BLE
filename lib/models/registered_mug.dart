class RegisteredMug {
  final String serialNo;

  /// A Frappe timestamp without an offset is in the site's time zone.
  /// Use this for display, without assuming that it represents UTC.
  final DateTime? registrationDate;

  const RegisteredMug({
    required this.serialNo,
    required this.registrationDate,
  });

  factory RegisteredMug.fromJson(Map<String, dynamic> json) {
    final serial = json['serial_no'];
    if (serial is! String || serial.trim().isEmpty) {
      throw const FormatException('Missing registered mug serial number.');
    }

    final rawDate = json['registration_date'];
    final date = rawDate is String ? DateTime.tryParse(rawDate.trim()) : null;
    if (rawDate != null && date == null) {
      throw const FormatException('Invalid mug registration date.');
    }

    return RegisteredMug(serialNo: serial.trim(), registrationDate: date);
  }
}
