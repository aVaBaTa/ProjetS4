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

** IMPORTANT
Ajouter aussi le ip_repo qui est dans la racine du projet dans les ip repositories

** POTENTIELLEMENT NÉCESSAIRE 

Créer un lecteur virtuel, le bloc design de vivado a besoin d'un fichier avec un nom salement long.
Si besoin, et qu'on vous dit que le nom de fichier fait trop de bytes, rouler

```
subst X: {LE PATH DU PROJET SUR VOTRE ORDI}\ProjetS4-UART
```

Ça va faire un driver virtuel, vous aller pouvoir ouvrir le PROJETS4-UART.xpr directement à partir de là, et ce problème là devrait être régler.

Il est aussi possible que vous devez ajouter à la main les liens vers les fichiers sources et le fichier de contraintes