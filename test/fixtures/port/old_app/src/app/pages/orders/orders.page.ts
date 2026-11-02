// A made-up screen that touches one thing from every capability the
// inventory knows. Not run, not built — only read by test/port_signals_test.dart.
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { AlertController, NavController, ToastController } from '@ionic/angular';
import { Validators } from '@angular/forms';
import { SecureStorage } from '@aparajita/capacitor-secure-storage';
import { LocalNotifications } from '@capacitor/local-notifications';
import { Geolocation } from '@capacitor/geolocation';
import { Browser } from '@capacitor/browser';
import { NativeBiometric } from 'capacitor-native-biometric';
import { PushNotifications } from '@capacitor/push-notifications';
import { App } from '@capacitor/app';

export class OrdersPage {
  readonly api = environment.apiUrl;

  constructor(
    private http: HttpClient,
    private toast: ToastController,
    private alerts: AlertController,
    private nav: NavController,
  ) {}

  load() {
    console.log('loading');
    const when = dayjs(order.createdAt).fromNow();
    const total = amount.toFixed(2);
    const digits = new Intl.NumberFormat('ar', { numberingSystem: 'arab' });
    const length = formatDuration(seconds);
    const size = formatBytes(file.size);
    const sorted = ids.sort((a, b) => a.localeCompare(b, 'ar', { numeric: true }));
    const name = getInitials(user.fullName);
    const email = ['', Validators.email];
    App.addListener('appUrlOpen', () => {});
    if (auth.hasRole('admin') || unreadCount > 0) this.nav.navigateForward('/orders');
    if (forceUpdate || remoteConfig.enabled) analytics.logEvent('open');
    SecureStorage.get('token');
    LocalNotifications.schedule({ notifications: [] });
    Geolocation.getCurrentPosition();
    Browser.open({ url: 'https://example.com' });
    NativeBiometric.verifyIdentity();
    PushNotifications.register();
    Filesystem.requestPermissions();
    new MediaRecorder(stream);
    handwriting.recognize(strokes);
    paypal.Buttons();
    this.http.get('/api/orders').subscribe({ error: (e: HttpErrorResponse) => {} });
    this.http.get(`${this.api}/sessions`);
    lock.showPinCode();
  }
}
