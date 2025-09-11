import i18next from 'i18next';
import Backend from 'i18next-fs-backend';
import middleware from 'i18next-http-middleware';
import path from 'path';

// Initialize i18next
i18next
  .use(Backend)
  .use(middleware.LanguageDetector)
  .init({
    // Debug mode in development
    debug: process.env.NODE_ENV === 'development',
    
    // Default language
    fallbackLng: 'en',
    
    // Supported languages
    supportedLngs: ['en', 'ar'],
    
    // Default namespace
    defaultNS: 'common',
    
    // Load multiple namespaces
    ns: ['common', 'auth', 'errors','success'],
    
    // Backend configuration
    backend: {
      // Path to load resources from
      loadPath: path.resolve(__dirname, '../locales/{{lng}}/{{ns}}.json'),
    },
    
    // Detect language from Accept-Language header
    detection: {
      // Order of detection
      order: ['header', 'querystring', 'cookie'],
      
      // Look for language in the headers
      lookupHeader: 'accept-language',
      
      // Look for language in the query string
      lookupQuerystring: 'lng',
      
      // Look for language in the cookie
      lookupCookie: 'i18next',
      
      // Cache language in cookie
      caches: ['cookie'],
    },
    
    // Interpolation options
    interpolation: {
      escapeValue: false, // React already escapes values
    },
  });

export default i18next;
export const i18nextMiddleware = middleware.handle(i18next);