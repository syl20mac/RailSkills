# 🎨 Prompt Cursor AI - Améliorations Visuelles RailSkills Web

**Projet :** RailSkills Web (frontend web)  
**Stack :** React/Vue + TypeScript  
**Inspiration :** Améliorations visuelles de l'app iOS RailSkills  
**Objectif :** Moderniser l'interface web avec design cohérent  
**Date :** 26 novembre 2025

---

## 🎯 Contexte

J'ai récemment modernisé l'**app iOS RailSkills** avec :
- ✨ Design glassmorphism moderne
- 💫 Animations fluides
- 🌓 Dark Mode optimisé
- 🎨 Composants réutilisables
- 📊 Cartes et badges colorés
- ✅ Barre de progression animée

**Je veux appliquer les mêmes améliorations à RailSkills Web** pour avoir une **cohérence visuelle** entre iOS et Web.

---

## 🎨 Charte graphique SNCF (à respecter)

### Couleurs officielles SNCF

```css
/* Couleurs claires/pastels */
--sncf-ambre: #EDD484;
--sncf-peche: #FDBE87;
--sncf-nude: #F8C1B8;
--sncf-dragee: #EFBAE1;
--sncf-parme: #C7B2DE;
--sncf-bleu-horizon: #A4C8E1;
--sncf-vert-eau: #A1D6CA;

/* Couleurs vives/moyennes */
--sncf-safran: #DAAA00;        /* Orange/Jaune */
--sncf-ocre: #DC582A;          /* Orange foncé */
--sncf-corail: #F2827F;        /* Rose/Rouge */
--sncf-vieux-rose: #F59BBB;
--sncf-lavande: #6558B1;       /* Violet */
--sncf-ceruleen: #0084D4;      /* Bleu SNCF principal */
--sncf-menthe: #00B388;        /* Vert SNCF */

/* Couleurs sombres */
--sncf-mordore: #4A412A;
--sncf-chocolat: #4F2910;
--sncf-burgundy: #651C32;
--sncf-aubergine: #3F2A56;
--sncf-bleu-marine: #00205B;
--sncf-cobalt: #003865;
--sncf-foret: #154734;

/* Couleurs sémantiques */
--color-primary: var(--sncf-ceruleen);    /* Bleu principal */
--color-secondary: var(--sncf-menthe);    /* Vert */
--color-accent: var(--sncf-ocre);         /* Orange */
--color-success: var(--sncf-menthe);      /* Vert */
--color-warning: var(--sncf-safran);      /* Orange/Jaune */
--color-error: var(--sncf-corail);        /* Rouge */
--color-info: var(--sncf-bleu-horizon);   /* Bleu clair */
```

### États de checklist

```css
/* 0 = Non validé */
--state-0: var(--sncf-corail);      /* Rouge */

/* 1 = Partiel */
--state-1: var(--sncf-safran);      /* Orange */

/* 2 = Validé */
--state-2: var(--sncf-menthe);      /* Vert */

/* 3 = Non traité */
--state-3: var(--sncf-bleu-horizon); /* Bleu clair */
```

---

## 🎯 Composants à créer/améliorer

### 1. **ModernCard** (Carte glassmorphism)

**Style CSS moderne :**

```css
.modern-card {
  background: rgba(255, 255, 255, 0.8);
  backdrop-filter: blur(10px) saturate(180%);
  -webkit-backdrop-filter: blur(10px) saturate(180%);
  border-radius: 20px;
  border: 1px solid rgba(0, 0, 0, 0.08);
  box-shadow: 0 8px 16px rgba(0, 0, 0, 0.06);
  padding: 24px;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.modern-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 12px 24px rgba(0, 0, 0, 0.1);
}

.modern-card--elevated {
  box-shadow: 0 16px 32px rgba(0, 0, 0, 0.12);
}

/* Dark mode */
.dark .modern-card {
  background: rgba(30, 30, 30, 0.8);
  border: 1px solid rgba(255, 255, 255, 0.12);
}
```

**Component React/Vue :**

```tsx
// ModernCard.tsx (React) ou ModernCard.vue (Vue)
interface ModernCardProps {
  children: React.ReactNode;
  elevated?: boolean;
  className?: string;
  onClick?: () => void;
}

export const ModernCard: React.FC<ModernCardProps> = ({ 
  children, 
  elevated = false, 
  className = '',
  onClick 
}) => {
  return (
    <div 
      className={`modern-card ${elevated ? 'modern-card--elevated' : ''} ${className}`}
      onClick={onClick}
    >
      {children}
    </div>
  );
};
```

---

### 2. **ModernProgressBar** (Barre de progression animée)

**Style CSS :**

```css
.progress-container {
  width: 100%;
  height: 16px;
  background: rgba(0, 0, 0, 0.08);
  border-radius: 999px;
  overflow: hidden;
  position: relative;
}

.progress-bar {
  height: 100%;
  background: linear-gradient(90deg, var(--sncf-ceruleen), var(--sncf-menthe));
  border-radius: 999px;
  transition: width 0.6s cubic-bezier(0.4, 0, 0.2, 1);
  position: relative;
  overflow: hidden;
}

.progress-bar::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 50%;
  background: linear-gradient(180deg, rgba(255,255,255,0.3), transparent);
  border-radius: 999px 999px 0 0;
}

.progress-indicator {
  position: absolute;
  right: -8px;
  top: 50%;
  transform: translateY(-50%);
  width: 12px;
  height: 12px;
  background: white;
  border-radius: 50%;
  box-shadow: 0 2px 8px rgba(0, 132, 212, 0.5);
}

@keyframes shimmer {
  0% { background-position: -200% 0; }
  100% { background-position: 200% 0; }
}
```

**Component :**

```tsx
interface ProgressBarProps {
  progress: number; // 0-100
  color?: string;
  showPercentage?: boolean;
  height?: number;
}

export const ModernProgressBar: React.FC<ProgressBarProps> = ({
  progress,
  color = 'var(--sncf-ceruleen)',
  showPercentage = true,
  height = 16
}) => {
  return (
    <div className="flex items-center gap-3">
      <div className="progress-container" style={{ height: `${height}px` }}>
        <div 
          className="progress-bar"
          style={{ 
            width: `${Math.min(100, Math.max(0, progress))}%`,
            background: color
          }}
        >
          <div className="progress-indicator" />
        </div>
      </div>
      {showPercentage && (
        <span className="text-sm font-semibold tabular-nums" style={{ color }}>
          {Math.round(progress)}%
        </span>
      )}
    </div>
  );
};
```

---

### 3. **StatusBadge** (Badge de statut)

**Style CSS :**

```css
.status-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  border-radius: 999px;
  font-size: 0.875rem;
  font-weight: 600;
  color: white;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  transition: all 0.2s ease;
}

.status-badge:hover {
  transform: scale(1.05);
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.15);
}

.status-badge--validated {
  background: linear-gradient(135deg, var(--sncf-menthe), #00c896);
}

.status-badge--partial {
  background: linear-gradient(135deg, var(--sncf-safran), #e8b700);
}

.status-badge--not-validated {
  background: linear-gradient(135deg, var(--sncf-corail), #ff8e8c);
}

.status-badge--not-processed {
  background: linear-gradient(135deg, var(--sncf-bleu-horizon), #b5d4e8);
}

.status-badge__icon {
  font-size: 1rem;
}
```

**Component :**

```tsx
type ChecklistState = 0 | 1 | 2 | 3;

interface StatusBadgeProps {
  state: ChecklistState;
  size?: 'small' | 'medium' | 'large';
  showLabel?: boolean;
}

const STATE_CONFIG = {
  0: { label: 'Non validé', icon: '✗', color: 'var(--sncf-corail)', class: 'not-validated' },
  1: { label: 'Partiel', icon: '◪', color: 'var(--sncf-safran)', class: 'partial' },
  2: { label: 'Validé', icon: '✓', color: 'var(--sncf-menthe)', class: 'validated' },
  3: { label: 'À traiter', icon: '○', color: 'var(--sncf-bleu-horizon)', class: 'not-processed' }
};

export const StatusBadge: React.FC<StatusBadgeProps> = ({ 
  state, 
  size = 'medium',
  showLabel = true 
}) => {
  const config = STATE_CONFIG[state];
  
  return (
    <span className={`status-badge status-badge--${config.class} status-badge--${size}`}>
      <span className="status-badge__icon">{config.icon}</span>
      {showLabel && <span>{config.label}</span>}
    </span>
  );
};
```

---

### 4. **StatCard** (Carte de statistique)

**Component :**

```tsx
interface StatCardProps {
  icon: string;
  value: string | number;
  label: string;
  color?: string;
  trend?: {
    value: number;
    isPositive: boolean;
  };
}

export const StatCard: React.FC<StatCardProps> = ({
  icon,
  value,
  label,
  color = 'var(--sncf-ceruleen)',
  trend
}) => {
  return (
    <ModernCard>
      <div className="flex items-start gap-4">
        <div 
          className="stat-icon"
          style={{ 
            background: `${color}15`,
            color 
          }}
        >
          {icon}
        </div>
        <div className="flex-1">
          <div className="text-3xl font-bold tabular-nums" style={{ color }}>
            {value}
          </div>
          <div className="text-sm text-gray-600 dark:text-gray-400 mt-1">
            {label}
          </div>
          {trend && (
            <div className={`text-xs mt-2 ${trend.isPositive ? 'text-green-600' : 'text-red-600'}`}>
              {trend.isPositive ? '↗' : '↘'} {Math.abs(trend.value)}%
            </div>
          )}
        </div>
      </div>
    </ModernCard>
  );
};
```

---

### 5. **Dashboard Header** (En-tête moderne)

**Component :**

```tsx
interface DashboardHeaderProps {
  totalDrivers: number;
  totalEvaluations: number;
  completionRate: number;
}

export const DashboardHeader: React.FC<DashboardHeaderProps> = ({
  totalDrivers,
  totalEvaluations,
  completionRate
}) => {
  return (
    <ModernCard elevated className="mb-6">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
            Tableau de bord RailSkills
          </h1>
          <p className="text-gray-600 dark:text-gray-400 mt-2">
            Suivi des compétences conducteurs CFL
          </p>
        </div>
        
        <div className="flex items-center gap-3">
          <div className="text-right">
            <div className="text-sm text-gray-500">Taux de complétion</div>
            <div className="text-2xl font-bold" style={{ color: 'var(--sncf-menthe)' }}>
              {completionRate}%
            </div>
          </div>
          
          {/* Circular Progress */}
          <svg width="80" height="80" viewBox="0 0 80 80">
            <circle
              cx="40"
              cy="40"
              r="36"
              fill="none"
              stroke="rgba(0,0,0,0.1)"
              strokeWidth="8"
            />
            <circle
              cx="40"
              cy="40"
              r="36"
              fill="none"
              stroke="url(#gradient)"
              strokeWidth="8"
              strokeLinecap="round"
              strokeDasharray={`${2 * Math.PI * 36}`}
              strokeDashoffset={`${2 * Math.PI * 36 * (1 - completionRate / 100)}`}
              transform="rotate(-90 40 40)"
              style={{ transition: 'stroke-dashoffset 0.6s ease' }}
            />
            <defs>
              <linearGradient id="gradient" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" stopColor="var(--sncf-ceruleen)" />
                <stop offset="100%" stopColor="var(--sncf-menthe)" />
              </linearGradient>
            </defs>
          </svg>
        </div>
      </div>
      
      {/* Stats rapides */}
      <div className="grid grid-cols-3 gap-4">
        <div className="stat-pill" style={{ background: 'var(--sncf-ceruleen)15' }}>
          <div className="text-2xl font-bold" style={{ color: 'var(--sncf-ceruleen)' }}>
            {totalDrivers}
          </div>
          <div className="text-xs text-gray-600">Conducteurs</div>
        </div>
        
        <div className="stat-pill" style={{ background: 'var(--sncf-menthe)15' }}>
          <div className="text-2xl font-bold" style={{ color: 'var(--sncf-menthe)' }}>
            {totalEvaluations}
          </div>
          <div className="text-xs text-gray-600">Évaluations</div>
        </div>
        
        <div className="stat-pill" style={{ background: 'var(--sncf-safran)15' }}>
          <div className="text-2xl font-bold" style={{ color: 'var(--sncf-safran)' }}>
            {Math.round(completionRate)}%
          </div>
          <div className="text-xs text-gray-600">Progression</div>
        </div>
      </div>
    </ModernCard>
  );
};
```

---

### 6. **DriverCard** (Carte conducteur)

**Component :**

```tsx
interface DriverCardProps {
  name: string;
  lastEvaluation?: Date;
  triennialDue?: Date;
  completionRate: number;
  onClick?: () => void;
}

export const DriverCard: React.FC<DriverCardProps> = ({
  name,
  lastEvaluation,
  triennialDue,
  completionRate,
  onClick
}) => {
  const initials = name.split(' ').map(n => n[0]).join('').slice(0, 2).toUpperCase();
  const daysRemaining = triennialDue 
    ? Math.floor((triennialDue.getTime() - Date.now()) / (1000 * 60 * 60 * 24))
    : null;
  
  const statusColor = daysRemaining === null ? 'gray' 
    : daysRemaining < 0 ? 'var(--sncf-corail)'
    : daysRemaining < 30 ? 'var(--sncf-safran)'
    : 'var(--sncf-menthe)';
  
  return (
    <ModernCard onClick={onClick} className="cursor-pointer hover:scale-[1.02] transition-transform">
      <div className="flex items-center gap-4">
        {/* Avatar avec initiales */}
        <div 
          className="w-16 h-16 rounded-full flex items-center justify-center text-white text-xl font-bold"
          style={{
            background: 'linear-gradient(135deg, var(--sncf-ceruleen), var(--sncf-lavande))'
          }}
        >
          {initials}
        </div>
        
        <div className="flex-1">
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
            {name}
          </h3>
          
          {lastEvaluation && (
            <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
              Dernière éval. : {lastEvaluation.toLocaleDateString('fr-FR')}
            </p>
          )}
          
          {daysRemaining !== null && (
            <div className="flex items-center gap-2 mt-2">
              <div 
                className="w-2 h-2 rounded-full"
                style={{ background: statusColor }}
              />
              <span className="text-xs" style={{ color: statusColor }}>
                {daysRemaining < 0 
                  ? `Échu depuis ${-daysRemaining} jours`
                  : `${daysRemaining} jours restants`}
              </span>
            </div>
          )}
        </div>
        
        <div className="flex flex-col items-end gap-2">
          <ModernProgressBar 
            progress={completionRate} 
            showPercentage={false}
            height={8}
          />
          <span className="text-sm font-semibold" style={{ color: statusColor }}>
            {Math.round(completionRate)}%
          </span>
        </div>
      </div>
    </ModernCard>
  );
};
```

---

### 7. **ChecklistRow** (Ligne de checklist)

**Component :**

```tsx
interface ChecklistRowProps {
  item: {
    id: string;
    title: string;
    category?: string;
  };
  state: ChecklistState;
  hasNote: boolean;
  isInteractive: boolean;
  onStateChange: (newState: ChecklistState) => void;
  onNoteTap: () => void;
}

export const ChecklistRow: React.FC<ChecklistRowProps> = ({
  item,
  state,
  hasNote,
  isInteractive,
  onStateChange,
  onNoteTap
}) => {
  const stateColor = `var(--state-${state})`;
  
  return (
    <ModernCard className="hover:shadow-lg transition-shadow">
      <div className="flex items-center gap-4">
        {/* Barre latérale colorée */}
        <div 
          className="w-1 h-16 rounded-full"
          style={{ background: stateColor }}
        />
        
        <div className="flex-1">
          <h4 className="font-medium text-gray-900 dark:text-white">
            {item.title}
          </h4>
          {item.category && (
            <p className="text-xs text-gray-500 mt-1">
              📁 {item.category}
            </p>
          )}
        </div>
        
        {/* Bouton note */}
        <button
          onClick={onNoteTap}
          className="note-button"
          disabled={!isInteractive}
        >
          <span className={hasNote ? 'text-blue-600' : 'text-gray-400'}>
            {hasNote ? '📝' : '📄'}
          </span>
        </button>
        
        {/* Badge de statut */}
        <StatusBadge state={state} />
      </div>
    </ModernCard>
  );
};
```

---

## 🎨 Système de design global

### Variables CSS à ajouter dans `styles/variables.css`

```css
:root {
  /* Couleurs SNCF */
  --sncf-ceruleen: #0084D4;
  --sncf-menthe: #00B388;
  --sncf-safran: #DAAA00;
  --sncf-corail: #F2827F;
  --sncf-bleu-horizon: #A4C8E1;
  --sncf-lavande: #6558B1;
  
  /* Couleurs sémantiques */
  --color-primary: var(--sncf-ceruleen);
  --color-success: var(--sncf-menthe);
  --color-warning: var(--sncf-safran);
  --color-error: var(--sncf-corail);
  
  /* États checklist */
  --state-0: var(--sncf-corail);
  --state-1: var(--sncf-safran);
  --state-2: var(--sncf-menthe);
  --state-3: var(--sncf-bleu-horizon);
  
  /* Spacing */
  --spacing-xs: 4px;
  --spacing-sm: 8px;
  --spacing-md: 16px;
  --spacing-lg: 24px;
  --spacing-xl: 32px;
  
  /* Border radius */
  --radius-sm: 8px;
  --radius-md: 12px;
  --radius-lg: 16px;
  --radius-xl: 20px;
  --radius-full: 999px;
  
  /* Shadows */
  --shadow-sm: 0 2px 4px rgba(0, 0, 0, 0.06);
  --shadow-md: 0 8px 16px rgba(0, 0, 0, 0.08);
  --shadow-lg: 0 16px 32px rgba(0, 0, 0, 0.12);
  
  /* Transitions */
  --transition-fast: 0.15s cubic-bezier(0.4, 0, 0.2, 1);
  --transition-base: 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  --transition-slow: 0.6s cubic-bezier(0.4, 0, 0.2, 1);
}

/* Dark mode */
.dark {
  --card-bg: rgba(30, 30, 30, 0.8);
  --text-primary: #ffffff;
  --text-secondary: #a0a0a0;
  --border-color: rgba(255, 255, 255, 0.12);
}

/* Light mode */
.light {
  --card-bg: rgba(255, 255, 255, 0.8);
  --text-primary: #1a1a1a;
  --text-secondary: #666666;
  --border-color: rgba(0, 0, 0, 0.08);
}
```

---

## 🎯 Pages à améliorer

### 1. **Dashboard / Page d'accueil**

**Layout moderne :**

```tsx
export const Dashboard = () => {
  return (
    <div className="container mx-auto px-6 py-8">
      {/* Header avec stats globales */}
      <DashboardHeader 
        totalDrivers={conducteurs.length}
        totalEvaluations={evaluations.length}
        completionRate={globalProgress}
      />
      
      {/* Grid de cartes stats */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <StatCard 
          icon="👤"
          value={totalDrivers}
          label="Conducteurs actifs"
          color="var(--sncf-ceruleen)"
        />
        <StatCard 
          icon="✓"
          value={completedEvals}
          label="Évaluations complètes"
          color="var(--sncf-menthe)"
        />
        <StatCard 
          icon="⚠"
          value={pendingEvals}
          label="En attente"
          color="var(--sncf-safran)"
        />
        <StatCard 
          icon="📊"
          value={`${avgProgress}%`}
          label="Progression moyenne"
          color="var(--sncf-lavande)"
        />
      </div>
      
      {/* Liste des conducteurs */}
      <div className="space-y-4">
        {conducteurs.map(driver => (
          <DriverCard key={driver.id} {...driver} />
        ))}
      </div>
    </div>
  );
};
```

---

### 2. **Page Checklist / Évaluation**

**Layout moderne :**

```tsx
export const ChecklistPage = () => {
  return (
    <div className="container mx-auto px-6 py-8">
      {/* Header conducteur + progression */}
      <ModernCard elevated className="mb-6">
        <div className="flex items-center gap-6">
          <div className="avatar">JD</div>
          <div className="flex-1">
            <h2 className="text-2xl font-bold">Jean Dupont</h2>
            <p className="text-gray-600">Évaluation triennale CFL</p>
          </div>
          <ModernProgressBar progress={65} />
        </div>
      </ModernCard>
      
      {/* Questions par catégorie */}
      {categories.map(category => (
        <div key={category.id} className="mb-6">
          <h3 className="text-lg font-semibold mb-4 flex items-center gap-2">
            📁 {category.name}
            <span className="text-sm text-gray-500">
              {category.completed}/{category.total}
            </span>
          </h3>
          
          <div className="space-y-3">
            {category.questions.map(question => (
              <ChecklistRow 
                key={question.id}
                item={question}
                state={question.state}
                hasNote={!!question.note}
                isInteractive={true}
                onStateChange={(state) => handleStateChange(question.id, state)}
                onNoteTap={() => handleNoteTap(question.id)}
              />
            ))}
          </div>
        </div>
      ))}
    </div>
  );
};
```

---

## 🌓 Dark Mode

### Ajouter le toggle Dark Mode

```tsx
export const DarkModeToggle = () => {
  const [isDark, setIsDark] = useState(false);
  
  useEffect(() => {
    document.documentElement.classList.toggle('dark', isDark);
  }, [isDark]);
  
  return (
    <button
      onClick={() => setIsDark(!isDark)}
      className="dark-mode-toggle"
    >
      {isDark ? '☀️' : '🌙'}
    </button>
  );
};
```

**Styles :**

```css
.dark-mode-toggle {
  position: fixed;
  bottom: 24px;
  right: 24px;
  width: 56px;
  height: 56px;
  border-radius: 50%;
  background: var(--card-bg);
  border: 1px solid var(--border-color);
  box-shadow: var(--shadow-lg);
  font-size: 24px;
  cursor: pointer;
  transition: all 0.3s ease;
  z-index: 1000;
}

.dark-mode-toggle:hover {
  transform: scale(1.1) rotate(15deg);
}
```

---

## 📱 Responsive Design

### Breakpoints (comme iOS)

```css
/* iPhone (compact) */
@media (max-width: 640px) {
  .modern-card {
    padding: 16px;
    border-radius: 16px;
  }
  
  .grid {
    grid-template-columns: 1fr;
  }
}

/* iPad (regular) */
@media (min-width: 641px) and (max-width: 1024px) {
  .grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

/* Desktop */
@media (min-width: 1025px) {
  .grid {
    grid-template-columns: repeat(4, 1fr);
  }
}
```

---

## ✨ Animations

### Transitions CSS

```css
/* Apparition de carte */
@keyframes slideIn {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.modern-card {
  animation: slideIn 0.4s cubic-bezier(0.4, 0, 0.2, 1);
}

/* Hover effects */
.modern-card {
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.modern-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 12px 24px rgba(0, 0, 0, 0.1);
}

/* Progress bar animation */
.progress-bar {
  transition: width 0.6s cubic-bezier(0.4, 0, 0.2, 1);
}

/* Badge pulse au changement */
@keyframes pulse {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.1); }
}

.status-badge--validated {
  animation: pulse 0.3s ease-in-out;
}
```

---

## 🎯 Prompt court pour Cursor AI

**Copier-coller dans Cursor (Cmd+L) sur le Mac mini :**

```
Modernise l'interface web RailSkills en créant des composants visuels cohérents avec l'app iOS.

CRÉER composants React/TypeScript:
1. ModernCard.tsx - Carte glassmorphism (backdrop-filter, border-radius 20px, shadow douce)
2. ModernProgressBar.tsx - Barre animée avec dégradé ceruleen→menthe, indicateur circulaire
3. StatusBadge.tsx - Badge coloré par état (0=corail, 1=safran, 2=menthe, 3=bleu-horizon)
4. StatCard.tsx - Carte de statistique avec icône et valeur
5. DashboardHeader.tsx - Header avec avatar, stats, progression circulaire
6. DriverCard.tsx - Carte conducteur avec avatar initiales, dates, progression

CRÉER styles:
7. styles/variables.css - Variables CSS couleurs SNCF, spacing, transitions
8. styles/components.css - Styles des composants avec dark mode

COULEURS SNCF à utiliser:
--sncf-ceruleen: #0084D4 (bleu principal)
--sncf-menthe: #00B388 (vert succès)
--sncf-safran: #DAAA00 (orange warning)
--sncf-corail: #F2827F (rouge erreur)
--sncf-bleu-horizon: #A4C8E1 (bleu clair)
--sncf-lavande: #6558B1 (violet)

DESIGN:
- Glassmorphism: backdrop-filter blur(10px), rgba backgrounds
- Border-radius: 16-20px partout
- Shadows: douces (0 8px 16px rgba(0,0,0,0.06))
- Transitions: cubic-bezier(0.4, 0, 0.2, 1)
- Spacing: 16-24px généreux
- Dégradés: linear-gradient pour progressions
- Dark mode: variables CSS adaptatives

ANIMATIONS:
- Cards: hover translateY(-4px)
- Progress: transition 0.6s
- Badges: pulse à la validation
- Apparition: slideIn 0.4s

RESPONSIVE:
- Mobile: 1 colonne
- Tablet: 2 colonnes
- Desktop: 4 colonnes

Tous les composants doivent:
- ✅ Support dark mode
- ✅ Accessibilité (ARIA)
- ✅ TypeScript strict
- ✅ Commentaires en français
- ✅ Props validées
- ✅ Animations fluides

Inspire-toi du design iOS moderne (glassmorphism, animations spring, badges colorés).
```

---

## 📋 Fichiers à créer/modifier

```
frontend/src/
├── components/
│   ├── ModernCard.tsx              ⭐ NOUVEAU
│   ├── ModernProgressBar.tsx       ⭐ NOUVEAU
│   ├── StatusBadge.tsx             ⭐ NOUVEAU
│   ├── StatCard.tsx                ⭐ NOUVEAU
│   ├── DashboardHeader.tsx         ⭐ NOUVEAU
│   └── DriverCard.tsx              ⭐ NOUVEAU
├── styles/
│   ├── variables.css               ⭐ NOUVEAU
│   └── components.css              ⭐ NOUVEAU
└── pages/
    ├── Dashboard.tsx               ✏️ AMÉLIORER
    └── ChecklistPage.tsx           ✏️ AMÉLIORER
```

---

## ✅ Critères de succès

- [ ] Tous les composants créés
- [ ] Variables CSS SNCF configurées
- [ ] Dark mode fonctionnel
- [ ] Animations fluides
- [ ] Responsive (mobile, tablet, desktop)
- [ ] Accessibilité (ARIA labels)
- [ ] TypeScript sans erreurs
- [ ] Cohérence visuelle avec iOS
- [ ] Performance optimale

---

## 🎉 Résultat attendu

**RailSkills Web modernisé avec :**
- ✨ Design glassmorphism comme iOS
- 💫 Animations fluides
- 🌓 Dark mode optimisé
- 🎨 Couleurs SNCF cohérentes
- 📱 Responsive parfait
- ♿ Accessibilité améliorée

**Cohérence totale entre iOS et Web !** 🚀

---

**Ce prompt est prêt pour Cursor AI sur le Mac mini !**


