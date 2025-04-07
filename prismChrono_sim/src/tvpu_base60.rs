// src/tvpu_base60.rs
// Optimisations avancées pour les opérations en base 60 dans l'unité de traitement vectoriel ternaire (TVPU)

use crate::core::{Trit, Tryte, Word};
use crate::tvpu::{TernaryVector, encode_base60_component, decode_base60_component};

/// Structure optimisée pour les calculs en base 60 (sexagésimal)
/// Particulièrement efficace pour les applications temporelles et angulaires
pub struct Base60Value {
    /// Heures ou degrés
    pub units: i32,
    /// Minutes
    pub minutes: i32,
    /// Secondes
    pub seconds: i32,
    /// Millisecondes ou fractions de seconde (optionnel)
    pub milliseconds: Option<i32>,
}

impl Base60Value {
    /// Crée une nouvelle valeur en base 60
    pub fn new(units: i32, minutes: i32, seconds: i32) -> Self {
        Base60Value {
            units,
            minutes,
            seconds,
            milliseconds: None,
        }
    }
    
    /// Ajoute des millisecondes à la valeur
    pub fn with_milliseconds(mut self, ms: i32) -> Self {
        self.milliseconds = Some(ms);
        self
    }
    
    /// Convertit la valeur en secondes totales
    pub fn to_total_seconds(&self) -> i32 {
        let mut total = self.units * 3600 + self.minutes * 60 + self.seconds;
        if let Some(ms) = self.milliseconds {
            total = total * 1000 + ms;
        }
        total
    }
    
    /// Convertit la valeur en représentation décimale
    pub fn to_decimal(&self) -> f64 {
        let mut decimal = self.units as f64 + (self.minutes as f64) / 60.0 + (self.seconds as f64) / 3600.0;
        if let Some(ms) = self.milliseconds {
            decimal += (ms as f64) / 3600000.0;
        }
        decimal
    }
    
    /// Crée une valeur à partir d'une représentation décimale
    pub fn from_decimal(decimal: f64) -> Self {
        let total_seconds = (decimal * 3600.0) as i32;
        let units = total_seconds / 3600;
        let minutes = (total_seconds % 3600) / 60;
        let seconds = total_seconds % 60;
        
        Base60Value {
            units,
            minutes,
            seconds,
            milliseconds: None,
        }
    }
    
    /// Convertit la valeur en vecteur ternaire optimisé
    pub fn to_ternary_vector(&self) -> TernaryVector {
        let mut result = TernaryVector::default_undefined();
        
        for i in 0..8 {
            if let Some(word_result) = result.word_mut(i) {
                let mut new_word = Word::default_zero();
                
                // Encoder les secondes dans les trits 0-2
                encode_base60_component(&mut new_word, self.seconds, 0);
                
                // Encoder les minutes dans les trits 3-5
                encode_base60_component(&mut new_word, self.minutes, 3);
                
                // Encoder les unités dans les trits 6-8
                encode_base60_component(&mut new_word, self.units, 6);
                
                // Si nous avons des millisecondes, les encoder dans les trits 9-11
                if let Some(ms) = self.milliseconds {
                    // Convertir les millisecondes en une valeur entre 0 et 999
                    let ms_scaled = ms % 1000;
                    
                    // Encoder les centaines, dizaines et unités des millisecondes
                    let ms_hundreds = ms_scaled / 100;
                    let ms_tens = (ms_scaled % 100) / 10;
                    let ms_units = ms_scaled % 10;
                    
                    // Encoder dans les trits appropriés
                    if i < 7 { // S'assurer que nous avons de l'espace dans le vecteur
                        encode_base60_component(&mut new_word, ms_units, 9);
                        encode_base60_component(&mut new_word, ms_tens, 12);
                        encode_base60_component(&mut new_word, ms_hundreds, 15);
                    }
                }
                
                *word_result = new_word;
            }
        }
        
        result
    }
    
    /// Crée une valeur à partir d'un vecteur ternaire optimisé
    pub fn from_ternary_vector(vector: &TernaryVector) -> Self {
        let mut result = Base60Value {
            units: 0,
            minutes: 0,
            seconds: 0,
            milliseconds: None,
        };
        
        if let Some(word) = vector.word(0) {
            // Décoder les composantes
            result.seconds = decode_base60_component(word, 0);
            result.minutes = decode_base60_component(word, 3);
            result.units = decode_base60_component(word, 6);
            
            // Tenter de décoder les millisecondes si présentes
            if let Some(word_ms) = vector.word(1) {
                let ms_units = decode_base60_component(word_ms, 0);
                let ms_tens = decode_base60_component(word_ms, 3);
                let ms_hundreds = decode_base60_component(word_ms, 6);
                
                result.milliseconds = Some(ms_hundreds * 100 + ms_tens * 10 + ms_units);
            }
        }
        
        result
    }
}

/// Addition optimisée de valeurs en base 60
/// Particulièrement efficace pour les calculs temporels et angulaires
pub fn add_base60(a: &Base60Value, b: &Base60Value) -> Base60Value {
    // Convertir en secondes totales pour simplifier l'addition
    let mut total_seconds_a = a.units * 3600 + a.minutes * 60 + a.seconds;
    let mut total_seconds_b = b.units * 3600 + b.minutes * 60 + b.seconds;
    
    // Gérer les millisecondes si présentes
    let mut total_ms = 0;
    let mut has_ms = false;
    
    if let Some(ms_a) = a.milliseconds {
        total_ms += ms_a;
        has_ms = true;
    }
    
    if let Some(ms_b) = b.milliseconds {
        total_ms += ms_b;
        has_ms = true;
    }
    
    // Gérer le dépassement des millisecondes
    if has_ms && total_ms >= 1000 {
        total_seconds_a += total_ms / 1000;
        total_ms %= 1000;
    }
    
    // Additionner les secondes
    let total_seconds = total_seconds_a + total_seconds_b;
    
    // Convertir en unités, minutes, secondes
    let units = total_seconds / 3600;
    let minutes = (total_seconds % 3600) / 60;
    let seconds = total_seconds % 60;
    
    // Créer le résultat
    let mut result = Base60Value::new(units, minutes, seconds);
    
    // Ajouter les millisecondes si nécessaire
    if has_ms {
        result = result.with_milliseconds(total_ms);
    }
    
    result
}

/// Soustraction optimisée de valeurs en base 60
/// Particulièrement efficace pour les calculs temporels et angulaires
pub fn sub_base60(a: &Base60Value, b: &Base60Value) -> Base60Value {
    // Convertir en secondes totales pour simplifier la soustraction
    let mut total_seconds_a = a.units * 3600 + a.minutes * 60 + a.seconds;
    let total_seconds_b = b.units * 3600 + b.minutes * 60 + b.seconds;
    
    // Gérer les millisecondes si présentes
    let mut total_ms_a = 0;
    let mut total_ms_b = 0;
    let mut has_ms = false;
    
    if let Some(ms_a) = a.milliseconds {
        total_ms_a = ms_a;
        has_ms = true;
    }
    
    if let Some(ms_b) = b.milliseconds {
        total_ms_b = ms_b;
        has_ms = true;
    }
    
    // Gérer l'emprunt pour les millisecondes
    let mut total_ms = 0;
    if has_ms {
        if total_ms_a < total_ms_b {
            total_seconds_a -= 1;
            total_ms_a += 1000;
        }
        total_ms = total_ms_a - total_ms_b;
    }
    
    // Soustraire les secondes
    let total_seconds = total_seconds_a - total_seconds_b;
    
    // Gérer les valeurs négatives
    let negative = total_seconds < 0;
    let abs_seconds = total_seconds.abs();
    
    // Convertir en unités, minutes, secondes
    let units = abs_seconds / 3600 * (if negative { -1 } else { 1 });
    let minutes = (abs_seconds % 3600) / 60;
    let seconds = abs_seconds % 60;
    
    // Créer le résultat
    let mut result = Base60Value::new(units, minutes, seconds);
    
    // Ajouter les millisecondes si nécessaire
    if has_ms {
        result = result.with_milliseconds(total_ms);
    }
    
    result
}

/// Multiplication optimisée d'une valeur en base 60 par un scalaire
/// Particulièrement efficace pour les calculs temporels et angulaires
pub fn mul_base60_scalar(a: &Base60Value, scalar: i32) -> Base60Value {
    // Convertir en secondes totales pour simplifier la multiplication
    let mut total_seconds = a.units * 3600 + a.minutes * 60 + a.seconds;
    
    // Multiplier par le scalaire
    total_seconds *= scalar;
    
    // Gérer les millisecondes si présentes
    let mut total_ms = 0;
    let mut has_ms = false;
    
    if let Some(ms) = a.milliseconds {
        total_ms = ms * scalar;
        has_ms = true;
        
        // Gérer le dépassement des millisecondes
        if total_ms >= 1000 {
            total_seconds += total_ms / 1000;
            total_ms %= 1000;
        }
    }
    
    // Convertir en unités, minutes, secondes
    let units = total_seconds / 3600;
    let minutes = (total_seconds % 3600) / 60;
    let seconds = total_seconds % 60;
    
    // Créer le résultat
    let mut result = Base60Value::new(units, minutes, seconds);
    
    // Ajouter les millisecondes si nécessaire
    if has_ms {
        result = result.with_milliseconds(total_ms);
    }
    
    result
}

/// Division optimisée d'une valeur en base 60 par un scalaire
/// Particulièrement efficace pour les calculs temporels et angulaires
pub fn div_base60_scalar(a: &Base60Value, scalar: i32) -> Base60Value {
    if scalar == 0 {
        return Base60Value::new(0, 0, 0); // Éviter la division par zéro
    }
    
    // Convertir en secondes totales pour simplifier la division
    let total_seconds = a.units * 3600 + a.minutes * 60 + a.seconds;
    
    // Calculer les millisecondes totales pour une précision accrue
    let mut total_ms = total_seconds * 1000;
    if let Some(ms) = a.milliseconds {
        total_ms += ms;
    }
    
    // Diviser les millisecondes totales
    total_ms /= scalar;
    
    // Reconvertir en unités, minutes, secondes, millisecondes
    let total_seconds = total_ms / 1000;
    let ms = total_ms % 1000;
    
    let units = total_seconds / 3600;
    let minutes = (total_seconds % 3600) / 60;
    let seconds = total_seconds % 60;
    
    // Créer le résultat
    Base60Value::new(units, minutes, seconds).with_milliseconds(ms)
}

/// Conversion optimisée entre différentes unités en base 60
/// Par exemple, convertir des heures en degrés (1 heure = 15 degrés)
pub fn convert_base60_units(value: &Base60Value, conversion_factor: f64) -> Base60Value {
    // Convertir en valeur décimale
    let decimal = value.to_decimal();
    
    // Appliquer le facteur de conversion
    let converted = decimal * conversion_factor;
    
    // Reconvertir en base 60
    Base60Value::from_decimal(converted)
}

/// Calcule la différence entre deux temps en base 60
/// Retourne la différence sous forme d'intervalle
pub fn time_difference(time1: &Base60Value, time2: &Base60Value) -> Base60Value {
    // Utiliser la fonction de soustraction existante
    sub_base60(time1, time2)
}

/// Ajoute un intervalle de temps à un temps de base
pub fn add_time_interval(base_time: &Base60Value, interval: &Base60Value) -> Base60Value {
    // Utiliser la fonction d'addition existante
    add_base60(base_time, interval)
}

/// Optimisation pour les calculs d'angles horaires
/// Convertit un temps sidéral et une ascension droite en angle horaire
pub fn calculate_hour_angle(sidereal_time: &Base60Value, right_ascension: &Base60Value) -> Base60Value {
    // L'angle horaire = temps sidéral - ascension droite
    let mut hour_angle = sub_base60(sidereal_time, right_ascension);
    
    // Normaliser l'angle horaire entre 0 et 24 heures
    while hour_angle.units < 0 {
        hour_angle.units += 24;
    }
    
    while hour_angle.units >= 24 {
        hour_angle.units -= 24;
    }
    
    hour_angle
}

/// Optimisation pour les calculs de lever/coucher d'astres
/// Calcule l'heure de lever/coucher d'un astre à partir de ses coordonnées
pub fn calculate_rise_set_time(declination: &Base60Value, observer_latitude: &Base60Value) -> Option<Base60Value> {
    // Formule simplifiée pour le calcul du lever/coucher
    // cos(hour_angle) = -tan(latitude) * tan(declination)
    
    // Convertir en valeurs décimales pour les calculs trigonométriques
    let dec_decimal = declination.to_decimal();
    let lat_decimal = observer_latitude.to_decimal();
    
    // Convertir en radians
    let dec_rad = dec_decimal * std::f64::consts::PI / 180.0;
    let lat_rad = lat_decimal * std::f64::consts::PI / 180.0;
    
    // Calculer le cosinus de l'angle horaire
    let cos_ha = -f64::tan(lat_rad) * f64::tan(dec_rad);
    
    // Vérifier si l'astre se lève/couche
    if cos_ha.abs() > 1.0 {
        return None; // L'astre ne se lève/couche jamais à cette latitude
    }
    
    // Calculer l'angle horaire en degrés
    let ha_deg = cos_ha.acos() * 180.0 / std::f64::consts::PI;
    
    // Convertir en heures (15 degrés = 1 heure)
    let ha_hours = ha_deg / 15.0;
    
    // Convertir en Base60Value
    Some(Base60Value::from_decimal(ha_hours))
}

/// Optimisation pour les calculs de temps sidéral
/// Calcule le temps sidéral local à partir du temps sidéral de Greenwich et de la longitude
pub fn calculate_local_sidereal_time(greenwich_sidereal_time: &Base60Value, longitude: &Base60Value) -> Base60Value {
    // Convertir la longitude en heures (15 degrés = 1 heure)
    let longitude_hours = convert_base60_units(longitude, 1.0 / 15.0);
    
    // Temps sidéral local = temps sidéral de Greenwich + longitude (en heures)
    let mut lst = add_base60(greenwich_sidereal_time, &longitude_hours);
    
    // Normaliser entre 0 et 24 heures
    while lst.units < 0 {
        lst.units += 24;
    }
    
    while lst.units >= 24 {
        lst.units -= 24;
    }
    
    lst
}

/// Optimisation pour les calculs d'équation du temps
/// Calcule la différence entre le temps solaire moyen et le temps solaire vrai
pub fn calculate_equation_of_time(day_of_year: i32) -> Base60Value {
    // Formule simplifiée de l'équation du temps
    // En réalité, cette formule est beaucoup plus complexe et dépend de plusieurs facteurs
    
    // Convertir le jour de l'année en angle (en radians)
    let angle = 2.0 * std::f64::consts::PI * (day_of_year as f64) / 365.0;
    
    // Calculer l'équation du temps (en minutes)
    // Cette formule est une approximation simple
    let eot_minutes = 9.87 * f64::sin(2.0 * angle) - 7.53 * f64::cos(angle) - 1.5 * f64::sin(angle);
    
    // Convertir en Base60Value
    let minutes = eot_minutes.floor() as i32;
    let seconds = ((eot_minutes - minutes as f64) * 60.0) as i32;
    
    Base60Value::new(0, minutes, seconds)
}

/// Optimisation pour les calculs de précession
/// Calcule la précession des équinoxes sur une période donnée
pub fn calculate_precession(coordinates: &Base60Value, years: f64) -> Base60Value {
    // La précession est d'environ 50.3 secondes d'arc par an
    let precession_seconds = 50.3 * years;
    
    // Convertir en degrés, minutes, secondes
    let total_seconds = precession_seconds as i32;
    let degrees = total_seconds / 3600;
    let minutes = (total_seconds % 3600) / 60;
    let seconds = total_seconds % 60;
    
    // Ajouter à la coordonnée originale
    let precession = Base60Value::new(degrees, minutes, seconds);
    add_base60(coordinates, &precession)
}