import 'api_service.dart';

class QrAttendanceService {
  static Future<Map<String, dynamic>> requestAttendance({
    required String token,
    required String studentId,
  }) async {
    try {
      final res = await ApiService.post('/attendance/request', body: {
        'token': token,
        'studentId': studentId,
      });
      return res;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getPendingRequests() async {
    try {
      final res = await ApiService.get('/attendance/pending');
      return res;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> approveRequest(String requestId) async {
    try {
      final res = await ApiService.post('/attendance/approve', body: {
        'requestId': requestId,
      });
      return res;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> rejectRequest(String requestId) async {
    try {
      final res = await ApiService.post('/attendance/reject', body: {
        'requestId': requestId,
      });
      return res;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
