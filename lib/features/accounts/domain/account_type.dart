/// Nature d'un compte. [storageValue] est la valeur écrite en base : elle ne
/// doit jamais changer (sinon migration).
enum AccountType {
  cash('cash'),
  mobileMoney('mobile_money'),
  bank('bank'),
  savings('savings');

  const AccountType(this.storageValue);

  final String storageValue;

  static AccountType fromStorage(String value) => values.firstWhere(
    (type) => type.storageValue == value,
    orElse: () =>
        throw ArgumentError.value(value, 'value', 'Type de compte inconnu'),
  );
}
