/// HTTP metod türleri. NetworkManager.send içinde kullanılır.
enum RequestType {
  get('GET'),
  post('POST'),
  patch('PATCH'),
  delete('DELETE');

  const RequestType(this.value);

  final String value;
}
