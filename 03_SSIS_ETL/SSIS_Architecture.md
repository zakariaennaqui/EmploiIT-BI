<!-- ============================================================
  PROJET 13 : Offres et Demandes d'Emploi IT
  Documentation des packages SSIS — SSISProjet_EmploiIT
============================================================= -->

# Architecture SSIS — SSISProjet_EmploiIT

## Vue d'ensemble

Le projet SSIS comporte deux packages principaux :

```
SSISProjet_EmploiIT/
├── Pkg_LoadDimensions.dtsx   ← Chargement des 7 dimensions
├── Pkg_LoadFact.dtsx         ← Chargement des 2 tables de faits
├── Connection Managers/
│   ├── CM_OLTP.conmgr        ← Connexion à DB_EmploiIT (source)
│   └── CM_DW.conmgr          ← Connexion à DW_EmploiIT (destination)
```

---

## Package 1 : Pkg_LoadDimensions.dtsx

### Flux de contrôle (Control Flow)

```
SQL_ViderDimensions (Execute SQL Task)
        │
        ├──► DF_LoadCompetence (Data Flow Task)
        │
        ├──► DF_LoadEntreprise (Data Flow Task)
        │         │
        │         └──► DF_LoadPoste (Data Flow Task)
        │
        ├──► DF_LoadContrat (Data Flow Task)
        │         │
        │         └──► DF_LoadVille (Data Flow Task)
        │
        └──► DF_LoadSecteur (Data Flow Task)
                  │
                  └──► DF_LoadCandidat (Data Flow Task)
```

### Tâche SQL : SQL_ViderDimensions

<!-- Exécute un TRUNCATE ordonné des tables de faits puis DELETE des dimensions : -->

```sql
TRUNCATE TABLE DW_EmploiIT.dbo.FactCandidatures;
TRUNCATE TABLE DW_EmploiIT.dbo.FactOffres;
DELETE FROM DW_EmploiIT.dbo.DimOffre;
DELETE FROM DW_EmploiIT.dbo.DimCandidat;
DELETE FROM DW_EmploiIT.dbo.DimCompetence;
DELETE FROM DW_EmploiIT.dbo.DimEntreprise;
DELETE FROM DW_EmploiIT.dbo.DimVille;
DELETE FROM DW_EmploiIT.dbo.DimSecteur;
DELETE FROM DW_EmploiIT.dbo.DimContrat;
DELETE FROM DW_EmploiIT.dbo.DimTemps;
```

### Flux de données types : DF_LoadCandidat

| Composant | Type | Description |
|-----------|------|-------------|
| SRC_Candidats | OLE DB Source (CM_OLTP) | SELECT * FROM Candidats |
| DST_DimCandidat | OLE DB Destination (CM_DW) | INSERT → DimCandidat |

---

## Package 2 : Pkg_LoadFact.dtsx

### Flux de contrôle (Control Flow)

```
SQL_ViderFaits (Execute SQL Task)
        │
        ├──► factOffres (Data Flow Task)
        │
        └──► factCandidatures (Data Flow Task)
```

### Flux de données : DF_LoadFactOffres

```
OLE DB Source (Offres × OffresCompetences JOIN)
        │
        ├──► Lookup (DimEntreprise)   → EntrepriseSK
        │         │ Lookup Match Output
        ├──► Lookup 1 (DimOffre)      → OffreSK
        │         │ Lookup Match Output
        ├──► Lookup 2 (DimCompetence) → CompetenceSK
        │         │ Lookup Match Output
        ├──► Lookup 3 (DimTemps - Publication) → DatePublicationSK
        │         │ Lookup Match Output
        └──► Lookup 4 (DimTemps - Expiration)  → DateExpirationSK
                  │ Lookup Match Output
                  └──► Union All → OLE DB Destination (FactOffres)
```

### Flux de données : DF_LoadFactCandidature

Mécanisme Lookup illustré :

```
CandidatID (NK)  ──►  Lookup (DimCandidat en RAM)  ──►  CandidatSK (SK)
                                    │
                              No Match → Redirection des erreurs
```

```
SRC_Candidatures (OLE DB Source)
        │
        ├──► LKP_DimCandidat  → CandidatSK
        │         │ Lookup Match Output
        ├──► LKP_DimOffre     → OffreSK
        │         │ Lookup Match Output
        └──► Lookup 2, 3...   → DateCandidatureSK, DateEntretienSK
                  │
                  └──► Union All → DST_FactCandidature (OLE DB Destination)
```

---

## Gestionnaires de connexion

| Nom | Type | Base de données |
|-----|------|-----------------|
| CM_OLTP | OLE DB (SQL Server) | DB_EmploiIT (source OLTP) |
| CM_DW   | OLE DB (SQL Server) | DW_EmploiIT (entrepôt DW) |

---

## Notes importantes

- **TRUNCATE avant DELETE** : L'ordre est critique car les tables de faits
  référencent les dimensions via des clés étrangères.
- **Lookup en RAM** : Les transformations Lookup chargent la dimension entière
  en mémoire pour des performances optimales.
- **No Match → Redirection** : Les lignes sans correspondance sont redirigées
  vers une sortie d'erreur pour assurer la qualité des données.
