import 'package:flutter_test/flutter_test.dart';

import '../scripts/src/port_endpoints.dart';

/// A path without its method is half a contract: `GET /orders` and
/// `POST /orders` are two endpoints with different bodies and replies, and two
/// Retrofit lines. These pin the shapes an old app writes them in.
void main() {
  List<String> of(String code) => extractEndpoints([code]);

  test('a call named after its method', () {
    expect(of("this.http.get<Order[]>('/orders')"), ['GET /orders']);
    expect(of("axios.post(`/orders/\${order.id}/cancel`)"), [
      'POST /orders/{id}/cancel',
    ]);
  });

  test('a variable base is dropped from the path', () {
    expect(of("this.http.delete(`\${environment.apiUrl}/sessions/\${id}`)"), [
      'DELETE /sessions/{id}',
    ]);
    expect(of("dio.put(baseUrl + '/profile')"), ['PUT /profile']);
  });

  test('Retrofit annotations, with or without a leading slash', () {
    expect(of('@GET("orders/{id}")'), ['GET /orders/{id}']);
    expect(of("@POST('/auth/login')"), ['POST /auth/login']);
  });

  test('fetch is GET unless it says otherwise', () {
    expect(of("fetch('/api/units')"), ['GET /api/units']);
    expect(of("fetch('/api/units', { method: 'POST', body })"), [
      'POST /api/units',
    ]);
  });

  test('a bare /api/ string has an unknown method until a call names it', () {
    expect(of("const URL = '/api/reports';"), ['? /api/reports']);
    expect(
      extractEndpoints([
        "const URL = '/api/reports';",
        "http.get('/api/reports')",
      ]),
      ['GET /api/reports'],
    );
  });

  test('storage keys and asset paths are not endpoints', () {
    expect(of("storage.get('token')"), isEmpty);
    expect(of("http.get('assets/i18n/ar.json')"), isEmpty);
  });
}
