// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get settings => 'Ajustes';

  @override
  String get sectionPreferences => 'Preferencias';

  @override
  String get sectionPrivacy => 'Privacidad';

  @override
  String get sectionAccount => 'Cuenta';

  @override
  String get appearance => 'Apariencia';

  @override
  String get appearanceSystem => 'Predeterminado del sistema';

  @override
  String get appearanceLight => 'Claro';

  @override
  String get appearanceDark => 'Oscuro';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Predeterminado del sistema';

  @override
  String get clearCache => 'Borrar caché';

  @override
  String get cacheCalculating => 'Calculando…';

  @override
  String get clearCacheBody =>
      'Se eliminarán los episodios descargados y las imágenes guardadas. Tu cuenta y tu biblioteca no se verán afectadas.';

  @override
  String get clearCacheDone => 'Caché borrada';

  @override
  String get cancel => 'Cancelar';

  @override
  String get clear => 'Borrar';

  @override
  String get marketing => 'Comunicaciones de marketing';

  @override
  String get marketingSubtitle =>
      'Ofertas, series nuevas y novedades. Cámbialo cuando quieras.';

  @override
  String get privacyManagement => 'Gestión de privacidad';

  @override
  String get privacySubtitle => 'Cookies y opciones de datos';

  @override
  String get privacyIntro =>
      'Elige cómo puede DramaByte usar cookies y tecnologías similares. Puedes cambiarlo en cualquier momento.';

  @override
  String get privacyEssential => 'Esenciales';

  @override
  String get privacyEssentialBody =>
      'Inicio de sesión, seguridad y reproducción. Siempre activas.';

  @override
  String get privacyAnalytics => 'Analítica';

  @override
  String get privacyAnalyticsBody =>
      'Nos ayuda a encontrar errores y mejorar la app.';

  @override
  String get privacyPersonalization => 'Personalización';

  @override
  String get privacyPersonalizationBody =>
      'Recomienda series según lo que ves.';

  @override
  String get membership => 'Gestionar membresía';

  @override
  String membershipActive(int days) {
    return 'VIP · $days días restantes';
  }

  @override
  String get membershipFree => 'Plan gratuito';

  @override
  String get membershipFreeBody =>
      'No eres miembro VIP. Recarga monedas para desbloquear episodios premium.';

  @override
  String get membershipManageBody =>
      'Las suscripciones se cobran y cancelan desde tu cuenta de la tienda de aplicaciones.';

  @override
  String get manageSubscription => 'Gestionar suscripción';

  @override
  String get getCoins => 'Recargar monedas';

  @override
  String get about => 'Acerca de';

  @override
  String aboutVersion(String version, String build) {
    return 'Versión $version ($build)';
  }

  @override
  String get termsOfService => 'Términos del servicio';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get licenses => 'Licencias de código abierto';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get deleteAccountSubtitle => 'Eliminar tus datos de forma permanente';

  @override
  String get deleteWarning =>
      'Esta acción no se puede deshacer. Se eliminarán tu perfil, monedas, biblioteca, historial y valoraciones, y se cerrará tu sesión.';

  @override
  String deleteTypeToConfirm(String word) {
    return 'Escribe $word para confirmar';
  }

  @override
  String get deleteConfirm => 'Verificar con Google y eliminar';

  @override
  String get deleteFailed =>
      'No se pudo eliminar tu cuenta. Inténtalo de nuevo.';

  @override
  String get savedOffline =>
      'Guardado en este dispositivo. Se sincronizará cuando vuelvas a estar en línea.';

  @override
  String clearCacheSize(String size) {
    return '$size en uso';
  }
}
