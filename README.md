# 🎮 Projet-S4: (NOM DE NOTRE PROJET)
![Statut du projet](https://img.shields.io/badge/statut-en%20cours%20de%20d%C3%A9veloppement-yellow)
![Licence](https://img.shields.io/badge/licence-MIT-blue)
## Description



# Projet S4 - UART & Système Embarqué (Zybo Z7-10)

Ce dépôt contient le projet matériel (Vivado v2024.1) et logiciel (Vitis Unified) pour le système embarqué développé dans le cadre du projet S4 (GEGI - Université de Sherbrooke). 

---

## 🛠️ Prérequis

Avant de commencer, assurez-vous d'avoir installé :
* **AMD Vivado v2024.1** (avec le support de la cible Zynq-7000)
* **AMD Vitis Unified IDE v2024.1**
* Les variables d'environnement de Xilinx configurées (si vous utilisez la ligne de commande).

---

## étape 1 : Rouler le script build.bat
- Aller dans scripts
- Rouler build.bat

## 📦 Étape 2 : Installation de la bibliothèque d'IPs `vivado-library`

Le projet utilise des interfaces matérielles spécifiques (notamment l'interface vidéo HDMI `TMDS`) fournies par Digilent. Cette bibliothèque doit être téléchargée et placée localement.

1. Téléchargez les sources de la bibliothèque sur le GitHub officiel de Digilent :
   👉 [Digilent vivado-library (GitHub)](https://github.com/digilent/vivado-library) (Téléchargez le fichier **ZIP** via le bouton *Code*).
2. Créez un dossier nommé `repo` à la racine de votre dossier de projet si ce n'est pas déjà fait.
3. Extrayez le contenu du ZIP dans ce dossier de manière à obtenir la structure suivante :

```text
ProjetS4-UART/
├── vivado-library <------ Mettre ici

4. Aller dans Vivado, dans les settings, onglet IP, onglet Repository, et mettre le bon path pour votre vivado-Library