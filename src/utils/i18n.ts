import { Request } from 'express';
import i18next from '../config/i18n';

/**
 * Translate a key based on the request's language
 * @param req Express request object
 * @param key Translation key
 * @param options Translation options
 * @returns Translated string
 */
export const t = (req: Request, key: string, options?: Record<string, any>): string => {
  return i18next.getFixedT(req.language || 'en')(key, options);
};

/**
 * Get the current language from the request
 * @param req Express request object
 * @returns Current language code
 */
export const getCurrentLanguage = (req: Request): string => {
  return req.language || 'en';
};

/**
 * Check if the current language is RTL
 * @param req Express request object
 * @returns Boolean indicating if the language is RTL
 */
export const isRTL = (req: Request): boolean => {
  const rtlLanguages = ['ar', 'he', 'fa', 'ur'];
  return rtlLanguages.includes(getCurrentLanguage(req));
};

/**
 * Get all translations for a namespace
 * @param req Express request object
 * @param namespace Namespace to get translations for
 * @returns Object containing all translations for the namespace
 */
export const getNamespaceTranslations = (req: Request, namespace: string): Record<string, any> => {
  return i18next.getResourceBundle(req.language || 'en', namespace);
};

/**
 * Translate a key for a specific language (without request object)
 * @param language Language code
 * @param key Translation key
 * @param options Translation options
 * @returns Translated string
 */
export const tl = (language: string, key: string, options?: Record<string, any>): string => {
  return i18next.getFixedT(language)(key, options);
};