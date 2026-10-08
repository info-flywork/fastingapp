/// HTTP metod türleri. NetworkManager.send içinde kullanılır.
enum RequestType {
  get('GET'),
  post('POST'),
  patch('PATCH'),
  put('PUT'),
  delete('DELETE');

  const RequestType(this.value);

  final String value;
}
