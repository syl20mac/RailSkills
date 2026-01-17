/**
 * utils.js - Fonctions utilitaires partagées
 */
const { v4: uuidv4 } = require('uuid');

/**
 * Générer un UUID v4
 * @returns {string}
 */
function generateUUID() {
  return uuidv4();
}

/**
 * Générer un UUID déterministe basé sur les détails du conducteur (si nécessaire)
 * NOTE : Pour un ID stable, un hash (SHA256) serait meilleur qu'un UUID basé sur un namespace.
 * Pour l'instant, on utilise un UUID v4 aléatoire comme dans le code original.
 * @param {object} driver - L'objet conducteur
 * @returns {string}
 */
function generateDriverUUID(driver) {
  // Le code original générait un v4 aléatoire, on garde ce comportement.
  // Si un ID stable est requis, il faudrait changer cette logique.
  return uuidv4();
}

/**
 * Diviser un tableau en chunks de taille définie
 * @param {Array} array - Le tableau à diviser
 * @param {number} size - La taille de chaque chunk
 * @returns {Array<Array>}
 */
function chunkArray(array, size) {
  const chunks = [];
  for (let i = 0; i < array.length; i += size) {
    chunks.push(array.slice(i, i + size));
  }
  return chunks;
}

/**
 * Parser une date depuis Excel (format flexible)
 * @param {any} value - La valeur de la cellule Excel
 * @returns {Date | undefined}
 */
function parseDate(value) {
  if (!value) return undefined;

  // Si c'est déjà une date
  if (value instanceof Date) {
    return value;
  }

  // Si c'est un nombre (format date Excel)
  if (typeof value === 'number') {
    // L'époque d'Excel commence le 30/12/1899 pour des raisons de compatibilité avec Lotus 1-2-3
    const excelEpoch = new Date(1899, 11, 30);
    return new Date(excelEpoch.getTime() + value * 86400000);
  }

  // Si c'est une chaîne
  if (typeof value === 'string') {
    // Essayer de parser en format ISO (ex: YYYY-MM-DD)
    const isoDate = new Date(value);
    if (!isNaN(isoDate.getTime())) {
      return isoDate;
    }

    // Essayer de parser en format FR (JJ/MM/AAAA)
    const parts = value.split('/');
    if (parts.length === 3) {
      const day = parseInt(parts[0], 10);
      const month = parseInt(parts[1], 10) - 1; // Mois est 0-indexé en JS
      const year = parseInt(parts[2], 10);
      const date = new Date(year, month, day);
      if (!isNaN(date.getTime())) {
        return date;
      }
    }
  }

  return undefined; // Format non reconnu
}

/**
 * Créer un mapping des en-têtes Excel (flexible)
 * @param {Array<string>} headers - La ligne d'en-tête
 * @returns {object}
 */
function createHeaderMap(headers) {
  const map = {};

  headers.forEach((header, index) => {
    const normalized = (header?.toString().toLowerCase().trim() || '');

    // Mapping flexible des colonnes
    if (normalized.includes('nom') && !normalized.includes('prénom')) {
      map.nom = index;
    } else if (normalized.includes('prénom') || normalized.includes('prenom') || normalized.includes('firstname')) {
      map.prenom = index;
    } else if (normalized.includes('cp') || normalized.includes('numéro') || normalized.includes('numero')) {
      map.cpNumber = index;
    } else if (normalized.includes('date') && (normalized.includes('limite') || normalized.includes('triennale'))) {
      map.triennialStart = index;
    }
  });

  return map;
}

module.exports = {
  generateUUID,
  generateDriverUUID,
  chunkArray,
  parseDate,
  createHeaderMap,
};
