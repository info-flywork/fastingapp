/// Tüm API modellerinin implement ettiği abstract base.
///
/// [fromJson] instance düzeyinde parse için, [toJson] serileştirme içindir.
abstract class BaseModel<T> {
  const BaseModel();

  T fromJson(Map<String, dynamic> json);

  Map<String, dynamic> toJson();
}
