import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @noteEnregistree.
  ///
  /// In fr, this message translates to:
  /// **', note enregistrée'**
  String get noteEnregistree;

  /// No description provided for @message10MinDeMeditation.
  ///
  /// In fr, this message translates to:
  /// **'10 min de méditation'**
  String get message10MinDeMeditation;

  /// No description provided for @message10MinutesDePleineConscienceParJourReduisentSignificativement.
  ///
  /// In fr, this message translates to:
  /// **'10 minutes de pleine conscience par jour réduisent significativement le stress et améliorent la régulation émotionnelle (Harvard Medical School).'**
  String
  get message10MinutesDePleineConscienceParJourReduisentSignificativement;

  /// No description provided for @message12CaracteresMinimum.
  ///
  /// In fr, this message translates to:
  /// **'12 caractères minimum'**
  String get message12CaracteresMinimum;

  /// No description provided for @message2GrandsFilmsDuCinema.
  ///
  /// In fr, this message translates to:
  /// **'2 grands films du cinéma'**
  String get message2GrandsFilmsDuCinema;

  /// No description provided for @message3SeancesDeSport.
  ///
  /// In fr, this message translates to:
  /// **'3 séances de sport'**
  String get message3SeancesDeSport;

  /// No description provided for @message8000PasParJour.
  ///
  /// In fr, this message translates to:
  /// **'8 000 pas par jour'**
  String get message8000PasParJour;

  /// No description provided for @acquerirUneNouvelleCompetenceChaqueAnneeLangueInstrumentProgrammation.
  ///
  /// In fr, this message translates to:
  /// **'Acquérir une nouvelle compétence chaque année — langue, instrument, programmation — entretient la neuroplasticité et élargit les opportunités.'**
  String
  get acquerirUneNouvelleCompetenceChaqueAnneeLangueInstrumentProgrammation;

  /// No description provided for @actions.
  ///
  /// In fr, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @actionsDuCommandement.
  ///
  /// In fr, this message translates to:
  /// **'Actions du commandement'**
  String get actionsDuCommandement;

  /// No description provided for @activerLesRappels.
  ///
  /// In fr, this message translates to:
  /// **'Activer les rappels'**
  String get activerLesRappels;

  /// No description provided for @activiteCreative.
  ///
  /// In fr, this message translates to:
  /// **'Activité créative'**
  String get activiteCreative;

  /// No description provided for @affichageDesCartes.
  ///
  /// In fr, this message translates to:
  /// **'Affichage des cartes'**
  String get affichageDesCartes;

  /// No description provided for @afficher.
  ///
  /// In fr, this message translates to:
  /// **'Afficher'**
  String get afficher;

  /// No description provided for @ajouterLeTag.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter le tag'**
  String get ajouterLeTag;

  /// No description provided for @ajouterUnTagAutocompletion.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un tag (autocomplétion)'**
  String get ajouterUnTagAutocompletion;

  /// No description provided for @ajouterModifierUneNote.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter/modifier une note'**
  String get ajouterModifierUneNote;

  /// No description provided for @alcool.
  ///
  /// In fr, this message translates to:
  /// **'Alcool'**
  String get alcool;

  /// No description provided for @alcoolTabacEcransOuJeuxPoseUnNomSur.
  ///
  /// In fr, this message translates to:
  /// **'Alcool, tabac, écrans ou jeux… Pose un nom sur ce qui te tient, note tes jours de liberté, et reprends le fil si tu trébuches.'**
  String get alcoolTabacEcransOuJeuxPoseUnNomSur;

  /// No description provided for @ann.
  ///
  /// In fr, this message translates to:
  /// **'Ann.'**
  String get ann;

  /// No description provided for @annuel.
  ///
  /// In fr, this message translates to:
  /// **'Annuel'**
  String get annuel;

  /// No description provided for @annuler.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get annuler;

  /// No description provided for @annee.
  ///
  /// In fr, this message translates to:
  /// **'Année {p0}'**
  String annee(Object p0);

  /// No description provided for @annee2.
  ///
  /// In fr, this message translates to:
  /// **'Année {p0} : {p1}{p2}. {p3}'**
  String annee2(Object p0, Object p1, Object p2, Object p3);

  /// No description provided for @apercu.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get apercu;

  /// No description provided for @apercuDuCommandement.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu du commandement'**
  String get apercuDuCommandement;

  /// No description provided for @apparence.
  ///
  /// In fr, this message translates to:
  /// **'Apparence'**
  String get apparence;

  /// No description provided for @appelerUnProche.
  ///
  /// In fr, this message translates to:
  /// **'Appeler un proche'**
  String get appelerUnProche;

  /// No description provided for @apprendreQuelqueChoseDeNouveau.
  ///
  /// In fr, this message translates to:
  /// **'Apprendre quelque chose de nouveau'**
  String get apprendreQuelqueChoseDeNouveau;

  /// No description provided for @appuyezPourAjouterOuModifierUneNote.
  ///
  /// In fr, this message translates to:
  /// **'Appuyez pour ajouter ou modifier une note.'**
  String get appuyezPourAjouterOuModifierUneNote;

  /// No description provided for @appuyezPourChoisirEntreCompleterOuAjouterUneNote.
  ///
  /// In fr, this message translates to:
  /// **'Appuyez pour choisir entre compléter ou ajouter une note.'**
  String get appuyezPourChoisirEntreCompleterOuAjouterUneNote;

  /// No description provided for @apres72hSansFumerLesBronchesCommencentASe.
  ///
  /// In fr, this message translates to:
  /// **'Après 72h sans fumer, les bronches commencent à se régénérer. Après 1 an, le risque d\'infarctus est divisé par deux.'**
  String get apres72hSansFumerLesBronchesCommencentASe;

  /// No description provided for @arreterDeFumer.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter de fumer'**
  String get arreterDeFumer;

  /// No description provided for @arreterLesEcransApres21h.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter les écrans après 21h'**
  String get arreterLesEcransApres21h;

  /// No description provided for @auLitAvant23h.
  ///
  /// In fr, this message translates to:
  /// **'Au lit avant 23h'**
  String get auLitAvant23h;

  /// No description provided for @auMoinsUnCaractereSpecial.
  ///
  /// In fr, this message translates to:
  /// **'Au moins un caractère spécial'**
  String get auMoinsUnCaractereSpecial;

  /// No description provided for @auMoinsUnChiffre.
  ///
  /// In fr, this message translates to:
  /// **'Au moins un chiffre'**
  String get auMoinsUnChiffre;

  /// No description provided for @auMoinsUneMajuscule.
  ///
  /// In fr, this message translates to:
  /// **'Au moins une majuscule'**
  String get auMoinsUneMajuscule;

  /// No description provided for @auMoinsUneMinuscule.
  ///
  /// In fr, this message translates to:
  /// **'Au moins une minuscule'**
  String get auMoinsUneMinuscule;

  /// No description provided for @aucunCommandementTrouve.
  ///
  /// In fr, this message translates to:
  /// **'Aucun commandement trouvé'**
  String get aucunCommandementTrouve;

  /// No description provided for @aucunHistoriquePourCeCommandementPourLeMomentContinuez.
  ///
  /// In fr, this message translates to:
  /// **'Aucun historique pour ce commandement pour le moment. Continuez, chaque action compte !'**
  String get aucunHistoriquePourCeCommandementPourLeMomentContinuez;

  /// No description provided for @aucunHistoriquePourCettePeriodeContinuezChaqueActionCompte.
  ///
  /// In fr, this message translates to:
  /// **'Aucun historique pour cette période. Continuez, chaque action compte !'**
  String get aucunHistoriquePourCettePeriodeContinuezChaqueActionCompte;

  /// No description provided for @aucunTagDisponiblePourLeMoment.
  ///
  /// In fr, this message translates to:
  /// **'Aucun tag disponible pour le moment.'**
  String get aucunTagDisponiblePourLeMoment;

  /// No description provided for @aucunTagPourLeMoment.
  ///
  /// In fr, this message translates to:
  /// **'Aucun tag pour le moment.'**
  String get aucunTagPourLeMoment;

  /// No description provided for @aucuneRechuteEnregistreeContinuezCommeCa.
  ///
  /// In fr, this message translates to:
  /// **'Aucune rechute enregistrée. Continuez comme ça !'**
  String get aucuneRechuteEnregistreeContinuezCommeCa;

  /// No description provided for @aucuneResistancePourLeMomentAjoutezCeQueVous.
  ///
  /// In fr, this message translates to:
  /// **'Aucune résistance pour le moment.\nAjoutez ce que vous voulez arrêter !'**
  String get aucuneResistancePourLeMomentAjoutezCeQueVous;

  /// No description provided for @aucuneResistanceTrouvee.
  ///
  /// In fr, this message translates to:
  /// **'Aucune résistance trouvée'**
  String get aucuneResistanceTrouvee;

  /// No description provided for @automatique.
  ///
  /// In fr, this message translates to:
  /// **'Automatique'**
  String get automatique;

  /// No description provided for @autres.
  ///
  /// In fr, this message translates to:
  /// **'Autres'**
  String get autres;

  /// No description provided for @belleRegularite.
  ///
  /// In fr, this message translates to:
  /// **'Belle régularité'**
  String get belleRegularite;

  /// No description provided for @bienvenueDansRituel.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue dans Rituel'**
  String get bienvenueDansRituel;

  /// No description provided for @boire15lDEau.
  ///
  /// In fr, this message translates to:
  /// **'Boire 1,5L d\'eau'**
  String get boire15lDEau;

  /// No description provided for @bonDepart.
  ///
  /// In fr, this message translates to:
  /// **'Bon départ'**
  String get bonDepart;

  /// No description provided for @capFranchi.
  ///
  /// In fr, this message translates to:
  /// **'Cap franchi'**
  String get capFranchi;

  /// No description provided for @ceChampEstObligatoire.
  ///
  /// In fr, this message translates to:
  /// **'Ce champ est obligatoire'**
  String get ceChampEstObligatoire;

  /// No description provided for @ceNEstPasLIntensiteQuiCompteC.
  ///
  /// In fr, this message translates to:
  /// **'Ce n\'est pas l\'intensité qui compte, c\'est la constance.'**
  String get ceNEstPasLIntensiteQuiCompteC;

  /// No description provided for @ceTagExisteDeja.
  ///
  /// In fr, this message translates to:
  /// **'Ce tag existe déjà.'**
  String get ceTagExisteDeja;

  /// No description provided for @cetUtilisateurAEteDesactive.
  ///
  /// In fr, this message translates to:
  /// **'Cet utilisateur a été désactivé.'**
  String get cetUtilisateurAEteDesactive;

  /// No description provided for @cetteActionEstIndisponiblePourLeMoment.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est indisponible pour le moment.'**
  String get cetteActionEstIndisponiblePourLeMoment;

  /// No description provided for @cetteActionEstIrreversible.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est irréversible.'**
  String get cetteActionEstIrreversible;

  /// No description provided for @cetteActionEstIrreversibleConfirmezLaSuppression.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est irréversible. Confirmez la suppression.'**
  String get cetteActionEstIrreversibleConfirmezLaSuppression;

  /// No description provided for @cetteAdresseEmailEstDejaUtilisee.
  ///
  /// In fr, this message translates to:
  /// **'Cette adresse email est déjà utilisée.'**
  String get cetteAdresseEmailEstDejaUtilisee;

  /// No description provided for @chaqueTagNeDoitPasDepasserCaracteres.
  ///
  /// In fr, this message translates to:
  /// **'Chaque tag ne doit pas dépasser {p0} caractères.'**
  String chaqueTagNeDoitPasDepasserCaracteres(Object p0);

  /// No description provided for @choisirUnEmoji.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un emoji'**
  String get choisirUnEmoji;

  /// No description provided for @choisirUneCouleurDaccent.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une couleur d’accent'**
  String get choisirUneCouleurDaccent;

  /// No description provided for @choisirUneDateDeReprise.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une date de reprise'**
  String get choisirUneDateDeReprise;

  /// No description provided for @clair.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get clair;

  /// No description provided for @commandementIntrouvable.
  ///
  /// In fr, this message translates to:
  /// **'Commandement introuvable.'**
  String get commandementIntrouvable;

  /// No description provided for @commandements.
  ///
  /// In fr, this message translates to:
  /// **'Commandements'**
  String get commandements;

  /// No description provided for @commandementsEtResistancesDetailParDefaut.
  ///
  /// In fr, this message translates to:
  /// **'Commandements et résistances — détail par défaut'**
  String get commandementsEtResistancesDetailParDefaut;

  /// No description provided for @commandementsEtResistancesListePlusDense.
  ///
  /// In fr, this message translates to:
  /// **'Commandements et résistances — liste plus dense'**
  String get commandementsEtResistancesListePlusDense;

  /// No description provided for @commencerDesMaintenant.
  ///
  /// In fr, this message translates to:
  /// **'Commencer dès maintenant'**
  String get commencerDesMaintenant;

  /// No description provided for @compact.
  ///
  /// In fr, this message translates to:
  /// **'Compact'**
  String get compact;

  /// No description provided for @completion.
  ///
  /// In fr, this message translates to:
  /// **'Complétion: {p0}%'**
  String completion(Object p0);

  /// No description provided for @confirmation.
  ///
  /// In fr, this message translates to:
  /// **'Confirmation'**
  String get confirmation;

  /// No description provided for @confirmer.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirmer;

  /// No description provided for @confirmerLaRechute.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la rechute ?'**
  String get confirmerLaRechute;

  /// No description provided for @confirmerLeMotDePasse.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get confirmerLeMotDePasse;

  /// No description provided for @confirmerLeNouveauMotDePasse.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le nouveau mot de passe'**
  String get confirmerLeNouveauMotDePasse;

  /// No description provided for @connexion.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get connexion;

  /// No description provided for @construisDesRoutinesQuiTeRessemblentEtDefaisCelles.
  ///
  /// In fr, this message translates to:
  /// **'Construis des routines qui te ressemblent et défais celles qui te freinent. Un seul endroit pour avancer à ton rythme.'**
  String get construisDesRoutinesQuiTeRessemblentEtDefaisCelles;

  /// No description provided for @contenuSensible.
  ///
  /// In fr, this message translates to:
  /// **'Contenu sensible'**
  String get contenuSensible;

  /// No description provided for @contrasteFaibleDetecteWcagAaVousPouvezContinuerMais.
  ///
  /// In fr, this message translates to:
  /// **'Contraste faible détecté (WCAG AA). Vous pouvez continuer, mais la lisibilité peut être réduite.'**
  String get contrasteFaibleDetecteWcagAaVousPouvezContinuerMais;

  /// No description provided for @couleurDaccent.
  ///
  /// In fr, this message translates to:
  /// **'Couleur d’accent'**
  String get couleurDaccent;

  /// No description provided for @couleurParDefautTheme.
  ///
  /// In fr, this message translates to:
  /// **'Couleur par défaut (thème)'**
  String get couleurParDefautTheme;

  /// No description provided for @coupDur.
  ///
  /// In fr, this message translates to:
  /// **'Coup dur'**
  String get coupDur;

  /// No description provided for @crash.
  ///
  /// In fr, this message translates to:
  /// **'Crash'**
  String get crash;

  /// No description provided for @creativite.
  ///
  /// In fr, this message translates to:
  /// **'Créativité'**
  String get creativite;

  /// No description provided for @creerLeCompte.
  ///
  /// In fr, this message translates to:
  /// **'Créer le compte'**
  String get creerLeCompte;

  /// No description provided for @creerUnCommandement.
  ///
  /// In fr, this message translates to:
  /// **'Créer un commandement'**
  String get creerUnCommandement;

  /// No description provided for @creerUnCompte.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get creerUnCompte;

  /// No description provided for @creezVotreCompte.
  ///
  /// In fr, this message translates to:
  /// **'Créez votre compte'**
  String get creezVotreCompte;

  /// No description provided for @dateDeReprise.
  ///
  /// In fr, this message translates to:
  /// **'Date de reprise'**
  String get dateDeReprise;

  /// No description provided for @description.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @descriptionOptionnelle.
  ///
  /// In fr, this message translates to:
  /// **'Description (optionnelle)'**
  String get descriptionOptionnelle;

  /// No description provided for @dimanche.
  ///
  /// In fr, this message translates to:
  /// **'Dimanche'**
  String get dimanche;

  /// No description provided for @detailDuCommandement.
  ///
  /// In fr, this message translates to:
  /// **'Détail du commandement'**
  String get detailDuCommandement;

  /// No description provided for @details.
  ///
  /// In fr, this message translates to:
  /// **'Détails'**
  String get details;

  /// No description provided for @effacer.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get effacer;

  /// No description provided for @email.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emoji.
  ///
  /// In fr, this message translates to:
  /// **'Emoji'**
  String get emoji;

  /// No description provided for @emojiSelectionne.
  ///
  /// In fr, this message translates to:
  /// **'Emoji sélectionné'**
  String get emojiSelectionne;

  /// No description provided for @enCours.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get enCours;

  /// No description provided for @enPause.
  ///
  /// In fr, this message translates to:
  /// **'En pause'**
  String get enPause;

  /// No description provided for @enPauseRepriseLe.
  ///
  /// In fr, this message translates to:
  /// **'En pause · reprise le {p0}'**
  String enPauseRepriseLe(Object p0);

  /// No description provided for @enRythme.
  ///
  /// In fr, this message translates to:
  /// **'En rythme'**
  String get enRythme;

  /// No description provided for @enregistrer.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get enregistrer;

  /// No description provided for @entrezVotreEmail.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre email'**
  String get entrezVotreEmail;

  /// No description provided for @envoyerLemail.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer l’email'**
  String get envoyerLemail;

  /// No description provided for @essentiel.
  ///
  /// In fr, this message translates to:
  /// **'Essentiel'**
  String get essentiel;

  /// No description provided for @ex10.
  ///
  /// In fr, this message translates to:
  /// **'Ex: 10'**
  String get ex10;

  /// No description provided for @exEtudierDart.
  ///
  /// In fr, this message translates to:
  /// **'Ex: Étudier Dart'**
  String get exEtudierDart;

  /// No description provided for @faceAuxAddictions.
  ///
  /// In fr, this message translates to:
  /// **'Face aux addictions'**
  String get faceAuxAddictions;

  /// No description provided for @faible.
  ///
  /// In fr, this message translates to:
  /// **'Faible'**
  String get faible;

  /// No description provided for @fauxPas.
  ///
  /// In fr, this message translates to:
  /// **'Faux pas'**
  String get fauxPas;

  /// No description provided for @fermer.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get fermer;

  /// No description provided for @filtres.
  ///
  /// In fr, this message translates to:
  /// **'Filtres'**
  String get filtres;

  /// No description provided for @finirUnLivre.
  ///
  /// In fr, this message translates to:
  /// **'Finir un livre'**
  String get finirUnLivre;

  /// No description provided for @fixeDesObjectifsParJourSemaineMoisOuAnnee.
  ///
  /// In fr, this message translates to:
  /// **'Fixe des objectifs par jour, semaine, mois ou année. Visualise ta régularité, célèbre tes séries et identifie où tu peux faire mieux.'**
  String get fixeDesObjectifsParJourSemaineMoisOuAnnee;

  /// No description provided for @force.
  ///
  /// In fr, this message translates to:
  /// **'Force : {p0}'**
  String force(Object p0);

  /// No description provided for @fort.
  ///
  /// In fr, this message translates to:
  /// **'Fort'**
  String get fort;

  /// No description provided for @frequence.
  ///
  /// In fr, this message translates to:
  /// **'Fréquence'**
  String get frequence;

  /// No description provided for @frequence2.
  ///
  /// In fr, this message translates to:
  /// **'Fréquence: {p0}'**
  String frequence2(Object p0);

  /// No description provided for @habitudeAncree.
  ///
  /// In fr, this message translates to:
  /// **'Habitude ancrée'**
  String get habitudeAncree;

  /// No description provided for @hebd.
  ///
  /// In fr, this message translates to:
  /// **'Hebd.'**
  String get hebd;

  /// No description provided for @hebdomadaire.
  ///
  /// In fr, this message translates to:
  /// **'Hebdomadaire'**
  String get hebdomadaire;

  /// No description provided for @heureDuRappel.
  ///
  /// In fr, this message translates to:
  /// **'Heure du rappel'**
  String get heureDuRappel;

  /// No description provided for @historiqueDesRechutes.
  ///
  /// In fr, this message translates to:
  /// **'Historique des rechutes'**
  String get historiqueDesRechutes;

  /// No description provided for @iconesFrequentesPourLesHabitudesAArreter.
  ///
  /// In fr, this message translates to:
  /// **'Icônes fréquentes pour les habitudes à arrêter'**
  String get iconesFrequentesPourLesHabitudesAArreter;

  /// No description provided for @identifiantsInvalides.
  ///
  /// In fr, this message translates to:
  /// **'Identifiants invalides.'**
  String get identifiantsInvalides;

  /// No description provided for @impossibleDeChargerLhistorique.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger l’historique.'**
  String get impossibleDeChargerLhistorique;

  /// No description provided for @impossibleDeModifierLeMotDePassePourCet.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de modifier le mot de passe pour cet utilisateur.'**
  String get impossibleDeModifierLeMotDePassePourCet;

  /// No description provided for @impossibleDeSupprimerLeComptePourCetUtilisateur.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de supprimer le compte pour cet utilisateur.'**
  String get impossibleDeSupprimerLeComptePourCetUtilisateur;

  /// No description provided for @inscription.
  ///
  /// In fr, this message translates to:
  /// **'Inscription'**
  String get inscription;

  /// No description provided for @jeudi.
  ///
  /// In fr, this message translates to:
  /// **'Jeudi'**
  String get jeudi;

  /// No description provided for @jeuxParis.
  ///
  /// In fr, this message translates to:
  /// **'Jeux & paris'**
  String get jeuxParis;

  /// No description provided for @jour.
  ///
  /// In fr, this message translates to:
  /// **'Jour {p0} {p1} {p2} : {p3}{p4}. {p5}'**
  String jour(Object p0, Object p1, Object p2, Object p3, Object p4, Object p5);

  /// No description provided for @joursActifs.
  ///
  /// In fr, this message translates to:
  /// **'Jours actifs'**
  String get joursActifs;

  /// No description provided for @jusquaCeQueJeReprenne.
  ///
  /// In fr, this message translates to:
  /// **'Jusqu’à ce que je reprenne'**
  String get jusquaCeQueJeReprenne;

  /// No description provided for @jaiCraque.
  ///
  /// In fr, this message translates to:
  /// **'J’ai craqué'**
  String get jaiCraque;

  /// No description provided for @jaiCraque2.
  ///
  /// In fr, this message translates to:
  /// **'J’ai craqué 😔'**
  String get jaiCraque2;

  /// No description provided for @jaiDejaUnCompte.
  ///
  /// In fr, this message translates to:
  /// **'J’ai déjà un compte'**
  String get jaiDejaUnCompte;

  /// No description provided for @lOmsRecommande150MinDActiviteModereePar.
  ///
  /// In fr, this message translates to:
  /// **'L\'OMS recommande 150 min d\'activité modérée par semaine. 3 séances suffisent pour atteindre ce seuil et améliorer durablement santé cardiaque et humeur.'**
  String get lOmsRecommande150MinDActiviteModereePar;

  /// No description provided for @lAdresseEmailNEstPasValide.
  ///
  /// In fr, this message translates to:
  /// **'L\'adresse email n\'est pas valide.'**
  String get lAdresseEmailNEstPasValide;

  /// No description provided for @lInscriptionAvecEmailEtMotDePasseN.
  ///
  /// In fr, this message translates to:
  /// **'L\'inscription avec email et mot de passe n\'est pas autorisée.'**
  String get lInscriptionAvecEmailEtMotDePasseN;

  /// No description provided for @laChuteNEstPasUnEchecLEchec.
  ///
  /// In fr, this message translates to:
  /// **'La chute n\'est pas un échec. L\'échec, c\'est de rester là où on est tombé.'**
  String get laChuteNEstPasUnEchecLEchec;

  /// No description provided for @laDescriptionNeDoitPasDepasserCaracteres.
  ///
  /// In fr, this message translates to:
  /// **'La description ne doit pas dépasser {p0} caractères.'**
  String laDescriptionNeDoitPasDepasserCaracteres(Object p0);

  /// No description provided for @laLumiereBleueBloqueLaMelatonineEtRetardeL.
  ///
  /// In fr, this message translates to:
  /// **'La lumière bleue bloque la mélatonine et retarde l\'endormissement de 1 à 3h. Couper les écrans le soir améliore profondément le sommeil.'**
  String get laLumiereBleueBloqueLaMelatonineEtRetardeL;

  /// No description provided for @laNoteNePeutPasDepasserCaracteres.
  ///
  /// In fr, this message translates to:
  /// **'La note ne peut pas dépasser {p0} caractères.'**
  String laNoteNePeutPasDepasserCaracteres(Object p0);

  /// No description provided for @laProgressionDuCycleEnCoursSeraRemiseA.
  ///
  /// In fr, this message translates to:
  /// **'La progression du cycle en cours sera remise à zéro.'**
  String get laProgressionDuCycleEnCoursSeraRemiseA;

  /// No description provided for @laProgressionNePeutPasDepasserLobjectif.
  ///
  /// In fr, this message translates to:
  /// **'La progression ne peut pas dépasser l’objectif'**
  String get laProgressionNePeutPasDepasserLobjectif;

  /// No description provided for @leCommandementEtSonHistoriqueSerontSupprimes.
  ///
  /// In fr, this message translates to:
  /// **'Le commandement et son historique seront supprimés.'**
  String get leCommandementEtSonHistoriqueSerontSupprimes;

  /// No description provided for @leMotDePasseDoitContenirAuMoins12.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins 12 caractères.'**
  String get leMotDePasseDoitContenirAuMoins12;

  /// No description provided for @leMotDePasseDoitContenirAuMoinsUn.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins un caractère spécial parmi : ! @ # \$ % ^ & * ( ) , . ? : | < >'**
  String get leMotDePasseDoitContenirAuMoinsUn;

  /// No description provided for @leMotDePasseDoitContenirAuMoinsUn2.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins un chiffre.'**
  String get leMotDePasseDoitContenirAuMoinsUn2;

  /// No description provided for @leMotDePasseDoitContenirAuMoinsUne.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins une lettre majuscule.'**
  String get leMotDePasseDoitContenirAuMoinsUne;

  /// No description provided for @leMotDePasseDoitContenirAuMoinsUne2.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins une lettre minuscule.'**
  String get leMotDePasseDoitContenirAuMoinsUne2;

  /// No description provided for @leMotDePasseEstTropFaibleOuTrop.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe est trop faible ou trop court.'**
  String get leMotDePasseEstTropFaibleOuTrop;

  /// No description provided for @leMotDePasseNeDoitPasContenirPlus.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe ne doit pas contenir plus de 2 caractères identiques consécutifs.'**
  String get leMotDePasseNeDoitPasContenirPlus;

  /// No description provided for @leNombreDeTagsNeDoitPasDepasser.
  ///
  /// In fr, this message translates to:
  /// **'Le nombre de tags ne doit pas dépasser {p0}.'**
  String leNombreDeTagsNeDoitPasDepasser(Object p0);

  /// No description provided for @leNouvelOrdreNaPasPuEtreSynchronisePour.
  ///
  /// In fr, this message translates to:
  /// **'Le nouvel ordre n’a pas pu être synchronisé pour le moment.'**
  String get leNouvelOrdreNaPasPuEtreSynchronisePour;

  /// No description provided for @leReordonnancementEstDisponibleUniquementEnModeManuelSans.
  ///
  /// In fr, this message translates to:
  /// **'Le réordonnancement est disponible uniquement en mode Manuel, sans filtre ni recherche.'**
  String get leReordonnancementEstDisponibleUniquementEnModeManuelSans;

  /// No description provided for @leTitreEstObligatoire.
  ///
  /// In fr, this message translates to:
  /// **'Le titre est obligatoire'**
  String get leTitreEstObligatoire;

  /// No description provided for @leTitreNeDoitPasDepasserCaracteres.
  ///
  /// In fr, this message translates to:
  /// **'Le titre ne doit pas dépasser {p0} caractères'**
  String leTitreNeDoitPasDepasserCaracteres(Object p0);

  /// No description provided for @leTitreNeDoitPasDepasserCaracteres2.
  ///
  /// In fr, this message translates to:
  /// **'Le titre ne doit pas dépasser {p0} caractères.'**
  String leTitreNeDoitPasDepasserCaracteres2(Object p0);

  /// No description provided for @leTitreNeDoitPasEtreVide.
  ///
  /// In fr, this message translates to:
  /// **'Le titre ne doit pas être vide.'**
  String get leTitreNeDoitPasEtreVide;

  /// No description provided for @lesEspacesNeSontPasAutorisesDansLeMot.
  ///
  /// In fr, this message translates to:
  /// **'Les espaces ne sont pas autorisés dans le mot de passe.'**
  String get lesEspacesNeSontPasAutorisesDansLeMot;

  /// No description provided for @lesJoursActifsDoiventEtreComprisEntre1Lundi.
  ///
  /// In fr, this message translates to:
  /// **'Les jours actifs doivent être compris entre 1 (lundi) et 7 (dimanche).'**
  String get lesJoursActifsDoiventEtreComprisEntre1Lundi;

  /// No description provided for @lesJoursActifsNeDoiventPasContenirDeDoublons.
  ///
  /// In fr, this message translates to:
  /// **'Les jours actifs ne doivent pas contenir de doublons.'**
  String get lesJoursActifsNeDoiventPasContenirDeDoublons;

  /// No description provided for @lesMotsDePasseNeCorrespondentPas.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas.'**
  String get lesMotsDePasseNeCorrespondentPas;

  /// No description provided for @lesEtudesMontrentQuAtteindre8000PasJour.
  ///
  /// In fr, this message translates to:
  /// **'Les études montrent qu\'atteindre 8 000 pas/jour réduit de 51 % le risque de mortalité prématurée (JAMA, 2021).'**
  String get lesEtudesMontrentQuAtteindre8000PasJour;

  /// No description provided for @lire20Minutes.
  ///
  /// In fr, this message translates to:
  /// **'Lire 20 minutes'**
  String get lire20Minutes;

  /// No description provided for @lireQuotidiennementReduitLeStressDe68En6.
  ///
  /// In fr, this message translates to:
  /// **'Lire quotidiennement réduit le stress de 68 % en 6 minutes selon une étude de l\'Université de Sussex. 20 minutes suffisent pour progresser durablement.'**
  String get lireQuotidiennementReduitLeStressDe68En6;

  /// No description provided for @lireUnLivreParMoisRepresente12LivresPar.
  ///
  /// In fr, this message translates to:
  /// **'Lire un livre par mois représente 12 livres par an. Les grands lecteurs développent un vocabulaire, une mémoire et une empathie supérieurs.'**
  String get lireUnLivreParMoisRepresente12LivresPar;

  /// No description provided for @lundi.
  ///
  /// In fr, this message translates to:
  /// **'Lundi'**
  String get lundi;

  /// No description provided for @ma.
  ///
  /// In fr, this message translates to:
  /// **'Ma'**
  String get ma;

  /// No description provided for @maintenirDesLiensSociauxFortsEstLUnDes.
  ///
  /// In fr, this message translates to:
  /// **'Maintenir des liens sociaux forts est l\'un des meilleurs prédicteurs de longévité et de bonheur (étude Harvard sur 80 ans).'**
  String get maintenirDesLiensSociauxFortsEstLUnDes;

  /// No description provided for @manuel.
  ///
  /// In fr, this message translates to:
  /// **'Manuel'**
  String get manuel;

  /// No description provided for @mardi.
  ///
  /// In fr, this message translates to:
  /// **'Mardi'**
  String get mardi;

  /// No description provided for @marquerCommeComplete.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme complété'**
  String get marquerCommeComplete;

  /// No description provided for @marquerCommeComplete2.
  ///
  /// In fr, this message translates to:
  /// **'Marquer {p0} comme complété ?'**
  String marquerCommeComplete2(Object p0);

  /// No description provided for @masquer.
  ///
  /// In fr, this message translates to:
  /// **'Masquer'**
  String get masquer;

  /// No description provided for @maximumTagsParCommandement.
  ///
  /// In fr, this message translates to:
  /// **'Maximum {p0} tags par commandement.'**
  String maximumTagsParCommandement(Object p0);

  /// No description provided for @me.
  ///
  /// In fr, this message translates to:
  /// **'Me'**
  String get me;

  /// No description provided for @mens.
  ///
  /// In fr, this message translates to:
  /// **'Mens.'**
  String get mens;

  /// No description provided for @mensuel.
  ///
  /// In fr, this message translates to:
  /// **'Mensuel'**
  String get mensuel;

  /// No description provided for @mercredi.
  ///
  /// In fr, this message translates to:
  /// **'Mercredi'**
  String get mercredi;

  /// No description provided for @mesCommandements.
  ///
  /// In fr, this message translates to:
  /// **'Mes commandements'**
  String get mesCommandements;

  /// No description provided for @mesResistances.
  ///
  /// In fr, this message translates to:
  /// **'Mes résistances'**
  String get mesResistances;

  /// No description provided for @mettreEnPause.
  ///
  /// In fr, this message translates to:
  /// **'Mettre en pause'**
  String get mettreEnPause;

  /// No description provided for @mettreAJour.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour'**
  String get mettreAJour;

  /// No description provided for @modificationDuMotDePasse.
  ///
  /// In fr, this message translates to:
  /// **'Modification du mot de passe'**
  String get modificationDuMotDePasse;

  /// No description provided for @modifier.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get modifier;

  /// No description provided for @modifierLaResistance.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la résistance'**
  String get modifierLaResistance;

  /// No description provided for @modifierLeCommandement.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le commandement'**
  String get modifierLeCommandement;

  /// No description provided for @motDePasse.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get motDePasse;

  /// No description provided for @motDePasseActuel.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe actuel'**
  String get motDePasseActuel;

  /// No description provided for @motDePasseIncorrect.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe incorrect.'**
  String get motDePasseIncorrect;

  /// No description provided for @motDePasseMisAJour.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe mis à jour.'**
  String get motDePasseMisAJour;

  /// No description provided for @motDePasseOublie.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié'**
  String get motDePasseOublie;

  /// No description provided for @moyen.
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get moyen;

  /// No description provided for @nonDemarres.
  ///
  /// In fr, this message translates to:
  /// **'Non démarrés'**
  String get nonDemarres;

  /// No description provided for @nonTerminesDAbord.
  ///
  /// In fr, this message translates to:
  /// **'Non terminés d\'abord'**
  String get nonTerminesDAbord;

  /// No description provided for @noteOptionnelle.
  ///
  /// In fr, this message translates to:
  /// **'Note (optionnelle)'**
  String get noteOptionnelle;

  /// No description provided for @note.
  ///
  /// In fr, this message translates to:
  /// **'Note — {p0}'**
  String note(Object p0);

  /// No description provided for @nourriture.
  ///
  /// In fr, this message translates to:
  /// **'Nourriture'**
  String get nourriture;

  /// No description provided for @nousSommesLeRefletDeNosHabitudes.
  ///
  /// In fr, this message translates to:
  /// **'Nous sommes le reflet de nos habitudes'**
  String get nousSommesLeRefletDeNosHabitudes;

  /// No description provided for @nouveauCommandement.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau commandement'**
  String get nouveauCommandement;

  /// No description provided for @nouveauMotDePasse.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get nouveauMotDePasse;

  /// No description provided for @nouvelleResistance.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle résistance'**
  String get nouvelleResistance;

  /// No description provided for @objectif.
  ///
  /// In fr, this message translates to:
  /// **'Objectif'**
  String get objectif;

  /// No description provided for @organisation.
  ///
  /// In fr, this message translates to:
  /// **'Organisation'**
  String get organisation;

  /// No description provided for @pageSur.
  ///
  /// In fr, this message translates to:
  /// **'Page {p0} sur {p1}'**
  String pageSur(Object p0, Object p1);

  /// No description provided for @pageSur2.
  ///
  /// In fr, this message translates to:
  /// **'Page {p0} sur {p1}. {p2}. {p3}'**
  String pageSur2(Object p0, Object p1, Object p2, Object p3);

  /// No description provided for @panneSeche.
  ///
  /// In fr, this message translates to:
  /// **'Panne sèche'**
  String get panneSeche;

  /// No description provided for @parametresDuCompte.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres du compte'**
  String get parametresDuCompte;

  /// No description provided for @partirEnVoyage.
  ///
  /// In fr, this message translates to:
  /// **'Partir en voyage'**
  String get partirEnVoyage;

  /// No description provided for @pasDeRepetitionDePlusDe2.
  ///
  /// In fr, this message translates to:
  /// **'Pas de répétition de plus de 2'**
  String get pasDeRepetitionDePlusDe2;

  /// No description provided for @peindreDessinerEcrireLaPratiqueCreativeReguliereReduitLe.
  ///
  /// In fr, this message translates to:
  /// **'Peindre, dessiner, écrire… La pratique créative régulière réduit le cortisol et stimule la neuroplasticité.'**
  String get peindreDessinerEcrireLaPratiqueCreativeReguliereReduitLe;

  /// No description provided for @personnalisationVisuelle.
  ///
  /// In fr, this message translates to:
  /// **'Personnalisation visuelle'**
  String get personnalisationVisuelle;

  /// No description provided for @personnaliserLaCouleurDuCommandement.
  ///
  /// In fr, this message translates to:
  /// **'Personnaliser la couleur du commandement'**
  String get personnaliserLaCouleurDuCommandement;

  /// No description provided for @personnaliserLiconeDuCommandement.
  ///
  /// In fr, this message translates to:
  /// **'Personnaliser l’icône du commandement'**
  String get personnaliserLiconeDuCommandement;

  /// No description provided for @plusDelan.
  ///
  /// In fr, this message translates to:
  /// **'Plus d’élan'**
  String get plusDelan;

  /// No description provided for @progression.
  ///
  /// In fr, this message translates to:
  /// **'Progression'**
  String get progression;

  /// No description provided for @progression2.
  ///
  /// In fr, this message translates to:
  /// **'Progression ↑'**
  String get progression2;

  /// No description provided for @progression3.
  ///
  /// In fr, this message translates to:
  /// **'Progression ↓'**
  String get progression3;

  /// No description provided for @periodePrecedente.
  ///
  /// In fr, this message translates to:
  /// **'Période précédente'**
  String get periodePrecedente;

  /// No description provided for @periodeSuivante.
  ///
  /// In fr, this message translates to:
  /// **'Période suivante'**
  String get periodeSuivante;

  /// No description provided for @quotid.
  ///
  /// In fr, this message translates to:
  /// **'Quotid.'**
  String get quotid;

  /// No description provided for @quotidien.
  ///
  /// In fr, this message translates to:
  /// **'Quotidien'**
  String get quotidien;

  /// No description provided for @rappels.
  ///
  /// In fr, this message translates to:
  /// **'Rappels'**
  String get rappels;

  /// No description provided for @rappelsDiscretsPourVosCommandementsEnCours.
  ///
  /// In fr, this message translates to:
  /// **'Rappels discrets pour vos commandements en cours'**
  String get rappelsDiscretsPourVosCommandementsEnCours;

  /// No description provided for @rechercher.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get rechercher;

  /// No description provided for @rechercherUnCommandement.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un commandement…'**
  String get rechercherUnCommandement;

  /// No description provided for @rechercherUnEmoji.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un emoji...'**
  String get rechercherUnEmoji;

  /// No description provided for @rechercherUneResistance.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une résistance…'**
  String get rechercherUneResistance;

  /// No description provided for @rechercher2.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher…'**
  String get rechercher2;

  /// No description provided for @recordJour.
  ///
  /// In fr, this message translates to:
  /// **'Record : {p0} jour{p1}'**
  String recordJour(Object p0, Object p1);

  /// No description provided for @releverUnDefiPhysique.
  ///
  /// In fr, this message translates to:
  /// **'Relever un défi physique'**
  String get releverUnDefiPhysique;

  /// No description provided for @reprendre.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre'**
  String get reprendre;

  /// No description provided for @reprendreAuProchainCycle.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre au prochain cycle'**
  String get reprendreAuProchainCycle;

  /// No description provided for @reprendreCeCycle.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre ce cycle'**
  String get reprendreCeCycle;

  /// No description provided for @reprendreLeCommandement.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre le commandement'**
  String get reprendreLeCommandement;

  /// No description provided for @reprise.
  ///
  /// In fr, this message translates to:
  /// **'Reprise'**
  String get reprise;

  /// No description provided for @resetDemain.
  ///
  /// In fr, this message translates to:
  /// **'Reset demain'**
  String get resetDemain;

  /// No description provided for @resetDemainAMinuitUtc.
  ///
  /// In fr, this message translates to:
  /// **'Reset demain à minuit UTC'**
  String get resetDemainAMinuitUtc;

  /// No description provided for @resetLe1erJanvier.
  ///
  /// In fr, this message translates to:
  /// **'Reset le 1er janvier {p0}'**
  String resetLe1erJanvier(Object p0);

  /// No description provided for @resetLe1er.
  ///
  /// In fr, this message translates to:
  /// **'Reset le 1er {p0}'**
  String resetLe1er(Object p0);

  /// No description provided for @resetLeLundi.
  ///
  /// In fr, this message translates to:
  /// **'Reset le lundi {p0} {p1}'**
  String resetLeLundi(Object p0, Object p1);

  /// No description provided for @retirerLaCompletion.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la complétion'**
  String get retirerLaCompletion;

  /// No description provided for @retirerLaCompletion2.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la complétion {p0} ?'**
  String retirerLaCompletion2(Object p0);

  /// No description provided for @retour.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get retour;

  /// No description provided for @retourALaConnexion.
  ///
  /// In fr, this message translates to:
  /// **'Retour à la connexion'**
  String get retourALaConnexion;

  /// No description provided for @retrouvezVosCommandements.
  ///
  /// In fr, this message translates to:
  /// **'Retrouvez vos commandements'**
  String get retrouvezVosCommandements;

  /// No description provided for @rituel.
  ///
  /// In fr, this message translates to:
  /// **'Rituel'**
  String get rituel;

  /// No description provided for @reduire.
  ///
  /// In fr, this message translates to:
  /// **'Réduire'**
  String get reduire;

  /// No description provided for @reessayer.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get reessayer;

  /// No description provided for @reinitialisationDuMotDePasse.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialisation du mot de passe'**
  String get reinitialisationDuMotDePasse;

  /// No description provided for @reinitialiser.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get reinitialiser;

  /// No description provided for @reinitialiserLeCycle.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser le cycle ?'**
  String get reinitialiserLeCycle;

  /// No description provided for @resistance.
  ///
  /// In fr, this message translates to:
  /// **'Résistance'**
  String get resistance;

  /// No description provided for @resistanceIntrouvable.
  ///
  /// In fr, this message translates to:
  /// **'Résistance introuvable.'**
  String get resistanceIntrouvable;

  /// No description provided for @resistances.
  ///
  /// In fr, this message translates to:
  /// **'Résistances'**
  String get resistances;

  /// No description provided for @sExposerRegulierementADesUvresMarquantesElargitL.
  ///
  /// In fr, this message translates to:
  /// **'S\'exposer régulièrement à des œuvres marquantes élargit l\'empathie, la culture générale et la capacité d\'analyse.'**
  String get sExposerRegulierementADesUvresMarquantesElargitL;

  /// No description provided for @sExposerALaNature2hParSemaineEst.
  ///
  /// In fr, this message translates to:
  /// **'S\'exposer à la nature 2h par semaine est associé à un meilleur bien-être physique et mental (Nature, 2019).'**
  String get sExposerALaNature2hParSemaineEst;

  /// No description provided for @samedi.
  ///
  /// In fr, this message translates to:
  /// **'Samedi'**
  String get samedi;

  /// No description provided for @sansEspace.
  ///
  /// In fr, this message translates to:
  /// **'Sans espace'**
  String get sansEspace;

  /// No description provided for @sansTitre.
  ///
  /// In fr, this message translates to:
  /// **'Sans titre'**
  String get sansTitre;

  /// No description provided for @sante.
  ///
  /// In fr, this message translates to:
  /// **'Santé'**
  String get sante;

  /// No description provided for @seConnecter.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get seConnecter;

  /// No description provided for @seDeconnecter.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get seDeconnecter;

  /// No description provided for @seFixerUnDefiSportifAnnuelMarathonRandonneeTriathlon.
  ///
  /// In fr, this message translates to:
  /// **'Se fixer un défi sportif annuel — marathon, randonnée, triathlon — structure la motivation sur le long terme et renforce la confiance en soi.'**
  String get seFixerUnDefiSportifAnnuelMarathonRandonneeTriathlon;

  /// No description provided for @semaine.
  ///
  /// In fr, this message translates to:
  /// **'Semaine {p0} ({p1})'**
  String semaine(Object p0, Object p1);

  /// No description provided for @semaine2.
  ///
  /// In fr, this message translates to:
  /// **'Semaine {p0} : {p1}{p2}. {p3}'**
  String semaine2(Object p0, Object p1, Object p2, Object p3);

  /// No description provided for @social.
  ///
  /// In fr, this message translates to:
  /// **'Social'**
  String get social;

  /// No description provided for @sombre.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get sombre;

  /// No description provided for @sortieDansLaNature.
  ///
  /// In fr, this message translates to:
  /// **'Sortie dans la nature'**
  String get sortieDansLaNature;

  /// No description provided for @sport.
  ///
  /// In fr, this message translates to:
  /// **'Sport'**
  String get sport;

  /// No description provided for @standard.
  ///
  /// In fr, this message translates to:
  /// **'Standard'**
  String get standard;

  /// No description provided for @statut.
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get statut;

  /// No description provided for @substances.
  ///
  /// In fr, this message translates to:
  /// **'Substances'**
  String get substances;

  /// No description provided for @suggestions.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions'**
  String get suggestions;

  /// No description provided for @suggestionsRapides.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions rapides'**
  String get suggestionsRapides;

  /// No description provided for @suisTaProgression.
  ///
  /// In fr, this message translates to:
  /// **'Suis ta progression'**
  String get suisTaProgression;

  /// No description provided for @suppressionDuCompte.
  ///
  /// In fr, this message translates to:
  /// **'Suppression du compte'**
  String get suppressionDuCompte;

  /// No description provided for @supprimer.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get supprimer;

  /// No description provided for @supprimerLaNote.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la note ?'**
  String get supprimerLaNote;

  /// No description provided for @supprimerLaResistance.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la résistance ?'**
  String get supprimerLaResistance;

  /// No description provided for @supprimerLeCommandement.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le commandement ?'**
  String get supprimerLeCommandement;

  /// No description provided for @supprimerLeCompte.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le compte'**
  String get supprimerLeCompte;

  /// No description provided for @supprimerLeCompte2.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le compte ?'**
  String get supprimerLeCompte2;

  /// No description provided for @surTaLancee.
  ///
  /// In fr, this message translates to:
  /// **'Sur ta lancée'**
  String get surTaLancee;

  /// No description provided for @serieLegendaire.
  ///
  /// In fr, this message translates to:
  /// **'Série légendaire'**
  String get serieLegendaire;

  /// No description provided for @seriePerdueJour.
  ///
  /// In fr, this message translates to:
  /// **'Série perdue : {p0} jour{p1}'**
  String seriePerdueJour(Object p0, Object p1);

  /// No description provided for @serieSolide.
  ///
  /// In fr, this message translates to:
  /// **'Série solide'**
  String get serieSolide;

  /// No description provided for @serie.
  ///
  /// In fr, this message translates to:
  /// **'Série ↑'**
  String get serie;

  /// No description provided for @serie2.
  ///
  /// In fr, this message translates to:
  /// **'Série ↓'**
  String get serie2;

  /// No description provided for @tabacVape.
  ///
  /// In fr, this message translates to:
  /// **'Tabac & vape'**
  String get tabacVape;

  /// No description provided for @tags.
  ///
  /// In fr, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @termines.
  ///
  /// In fr, this message translates to:
  /// **'Terminés'**
  String get termines;

  /// No description provided for @terminesDAbord.
  ///
  /// In fr, this message translates to:
  /// **'Terminés d\'abord'**
  String get terminesDAbord;

  /// No description provided for @titre.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get titre;

  /// No description provided for @tous.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get tous;

  /// No description provided for @tousLesCreneauxUtilisentCetteHeureLocaleTouchezPour.
  ///
  /// In fr, this message translates to:
  /// **'Tous les créneaux utilisent cette heure (locale). Touchez pour modifier.'**
  String get tousLesCreneauxUtilisentCetteHeureLocaleTouchezPour;

  /// No description provided for @toutes.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get toutes;

  /// No description provided for @travail.
  ///
  /// In fr, this message translates to:
  /// **'Travail'**
  String get travail;

  /// No description provided for @tri.
  ///
  /// In fr, this message translates to:
  /// **'Tri'**
  String get tri;

  /// No description provided for @tropDeTentativesVeuillezReessayerPlusTard.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives. Veuillez réessayer plus tard.'**
  String get tropDeTentativesVeuillezReessayerPlusTard;

  /// No description provided for @tresFort.
  ///
  /// In fr, this message translates to:
  /// **'Très fort'**
  String get tresFort;

  /// No description provided for @unEmailDeReinitialisationAEteEnvoyeSiLadresse.
  ///
  /// In fr, this message translates to:
  /// **'Un email de réinitialisation a été envoyé (si l’adresse existe).'**
  String get unEmailDeReinitialisationAEteEnvoyeSiLadresse;

  /// No description provided for @unSommeilRegulierAvantMinuitAmelioreLaQualiteDes.
  ///
  /// In fr, this message translates to:
  /// **'Un sommeil régulier avant minuit améliore la qualité des cycles de sommeil profond, essentiels à la mémoire et à la récupération.'**
  String get unSommeilRegulierAvantMinuitAmelioreLaQualiteDes;

  /// No description provided for @unTagNePeutPasDepasserCaracteres.
  ///
  /// In fr, this message translates to:
  /// **'Un tag ne peut pas dépasser {p0} caractères.'**
  String unTagNePeutPasDepasserCaracteres(Object p0);

  /// No description provided for @uneErreurEstSurvenueLorsDeLAuthentificationVeuillez.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue lors de l\'authentification. Veuillez réessayer.'**
  String get uneErreurEstSurvenueLorsDeLAuthentificationVeuillez;

  /// No description provided for @uneErreurEstSurvenueLorsDeLaModification.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue lors de la modification.'**
  String get uneErreurEstSurvenueLorsDeLaModification;

  /// No description provided for @uneErreurEstSurvenueLorsDeLaSynchronisation.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue lors de la synchronisation.'**
  String get uneErreurEstSurvenueLorsDeLaSynchronisation;

  /// No description provided for @uneErreurEstSurvenueVeuillezReessayer.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Veuillez réessayer.'**
  String get uneErreurEstSurvenueVeuillezReessayer;

  /// No description provided for @uneHydratationSuffisanteAmelioreLaConcentrationLEnergieEt.
  ///
  /// In fr, this message translates to:
  /// **'Une hydratation suffisante améliore la concentration, l\'énergie et la digestion. L\'OMS recommande 1,5 à 2L par jour.'**
  String get uneHydratationSuffisanteAmelioreLaConcentrationLEnergieEt;

  /// No description provided for @uneNotificationParTypeDeFrequenceQuotidienHebdoMensuel.
  ///
  /// In fr, this message translates to:
  /// **'Une notification par type de fréquence (quotidien, hebdo, mensuel, annuel) lorsqu’il reste au moins un commandement non terminé pour la période en cours.'**
  String get uneNotificationParTypeDeFrequenceQuotidienHebdoMensuel;

  /// No description provided for @utilisateurConnecte.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur connecté{p0}'**
  String utilisateurConnecte(Object p0);

  /// No description provided for @utilisateurIntrouvable.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur introuvable.'**
  String get utilisateurIntrouvable;

  /// No description provided for @valider.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get valider;

  /// No description provided for @vendredi.
  ///
  /// In fr, this message translates to:
  /// **'Vendredi'**
  String get vendredi;

  /// No description provided for @veuillezEntrerUnNombreValide.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un nombre valide'**
  String get veuillezEntrerUnNombreValide;

  /// No description provided for @veuillezEntrerUnTitreMin2.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un titre (min. 2)'**
  String get veuillezEntrerUnTitreMin2;

  /// No description provided for @veuillezEntrerUneAdresseEmailValide.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer une adresse email valide'**
  String get veuillezEntrerUneAdresseEmailValide;

  /// No description provided for @veuillezRespecterToutesLesReglesDuMotDePasse.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez respecter toutes les règles du mot de passe.'**
  String get veuillezRespecterToutesLesReglesDuMotDePasse;

  /// No description provided for @veuillezVousConnecterAvantDeModifierLeMotDe.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez vous connecter avant de modifier le mot de passe.'**
  String get veuillezVousConnecterAvantDeModifierLeMotDe;

  /// No description provided for @veuillezVousConnecterAvantDeSupprimerLeCompte.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez vous connecter avant de supprimer le compte.'**
  String get veuillezVousConnecterAvantDeSupprimerLeCompte;

  /// No description provided for @veuillezVousReconnecterAvantDeModifierLeMotDe.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez vous reconnecter avant de modifier le mot de passe ou de supprimer le compte.'**
  String get veuillezVousReconnecterAvantDeModifierLeMotDe;

  /// No description provided for @voirLaNote.
  ///
  /// In fr, this message translates to:
  /// **'Voir la note'**
  String get voirLaNote;

  /// No description provided for @voirLaNoteDuCycle.
  ///
  /// In fr, this message translates to:
  /// **'Voir la note du cycle'**
  String get voirLaNoteDuCycle;

  /// No description provided for @voirLeDetail.
  ///
  /// In fr, this message translates to:
  /// **'Voir le détail'**
  String get voirLeDetail;

  /// No description provided for @voirPlus.
  ///
  /// In fr, this message translates to:
  /// **'Voir plus'**
  String get voirPlus;

  /// No description provided for @vousAllezRemettreAZeroVotreSerieDeJour.
  ///
  /// In fr, this message translates to:
  /// **'Vous allez remettre à zéro votre série de {p0} jour{p1}.'**
  String vousAllezRemettreAZeroVotreSerieDeJour(Object p0, Object p1);

  /// No description provided for @voyagerAuMoinsUneFoisParAnExposeA.
  ///
  /// In fr, this message translates to:
  /// **'Voyager au moins une fois par an expose à de nouvelles cultures, stimule la curiosité et renforce la résilience face à l\'imprévu.'**
  String get voyagerAuMoinsUneFoisParAnExposeA;

  /// No description provided for @verificationDeLaSession.
  ///
  /// In fr, this message translates to:
  /// **'Vérification de la session...'**
  String get verificationDeLaSession;

  /// No description provided for @verifiezVotreConnexionInternetPuisReessayez.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre connexion internet puis réessayez.'**
  String get verifiezVotreConnexionInternetPuisReessayez;

  /// No description provided for @zoneRouge.
  ///
  /// In fr, this message translates to:
  /// **'Zone rouge'**
  String get zoneRouge;

  /// No description provided for @anneeManquee.
  ///
  /// In fr, this message translates to:
  /// **'année manquée'**
  String get anneeManquee;

  /// No description provided for @anneesManquees.
  ///
  /// In fr, this message translates to:
  /// **'années manquées'**
  String get anneesManquees;

  /// No description provided for @anneesReussies.
  ///
  /// In fr, this message translates to:
  /// **'années réussies'**
  String get anneesReussies;

  /// No description provided for @deLa.
  ///
  /// In fr, this message translates to:
  /// **'de la {p0}'**
  String deLa(Object p0);

  /// No description provided for @decembre.
  ///
  /// In fr, this message translates to:
  /// **'décembre'**
  String get decembre;

  /// No description provided for @enCours2.
  ///
  /// In fr, this message translates to:
  /// **'en cours'**
  String get enCours2;

  /// No description provided for @enPause2.
  ///
  /// In fr, this message translates to:
  /// **'en pause'**
  String get enPause2;

  /// No description provided for @fevrier.
  ///
  /// In fr, this message translates to:
  /// **'février'**
  String get fevrier;

  /// No description provided for @jourInactif.
  ///
  /// In fr, this message translates to:
  /// **'jour inactif'**
  String get jourInactif;

  /// No description provided for @jourManque.
  ///
  /// In fr, this message translates to:
  /// **'jour manqué'**
  String get jourManque;

  /// No description provided for @jourSansCraquer.
  ///
  /// In fr, this message translates to:
  /// **'jour sans craquer'**
  String get jourSansCraquer;

  /// No description provided for @joursManques.
  ///
  /// In fr, this message translates to:
  /// **'jours manqués'**
  String get joursManques;

  /// No description provided for @joursReussis.
  ///
  /// In fr, this message translates to:
  /// **'jours réussis'**
  String get joursReussis;

  /// No description provided for @joursSansCraquer.
  ///
  /// In fr, this message translates to:
  /// **'jours sans craquer'**
  String get joursSansCraquer;

  /// No description provided for @laSemaine.
  ///
  /// In fr, this message translates to:
  /// **'la semaine {p0} ({p1})'**
  String laSemaine(Object p0, Object p1);

  /// No description provided for @lannee.
  ///
  /// In fr, this message translates to:
  /// **'l’année {p0}'**
  String lannee(Object p0);

  /// No description provided for @moisManque.
  ///
  /// In fr, this message translates to:
  /// **'mois manqué'**
  String get moisManque;

  /// No description provided for @moisManques.
  ///
  /// In fr, this message translates to:
  /// **'mois manqués'**
  String get moisManques;

  /// No description provided for @moisReussis.
  ///
  /// In fr, this message translates to:
  /// **'mois réussis'**
  String get moisReussis;

  /// No description provided for @objectifAtteint.
  ///
  /// In fr, this message translates to:
  /// **'objectif atteint'**
  String get objectifAtteint;

  /// No description provided for @objectifNonAtteint.
  ///
  /// In fr, this message translates to:
  /// **'objectif non atteint'**
  String get objectifNonAtteint;

  /// No description provided for @semaineManquee.
  ///
  /// In fr, this message translates to:
  /// **'semaine manquée'**
  String get semaineManquee;

  /// No description provided for @semainesManquees.
  ///
  /// In fr, this message translates to:
  /// **'semaines manquées'**
  String get semainesManquees;

  /// No description provided for @semainesReussies.
  ///
  /// In fr, this message translates to:
  /// **'semaines réussies'**
  String get semainesReussies;

  /// No description provided for @remisAZero.
  ///
  /// In fr, this message translates to:
  /// **'{p0} {p1} remis à zéro'**
  String remisAZero(Object p0, Object p1);

  /// No description provided for @remisAZero2.
  ///
  /// In fr, this message translates to:
  /// **'{p0} {p1} {p2} remis à zéro'**
  String remisAZero2(Object p0, Object p1, Object p2);

  /// No description provided for @aCompleterAujourdhuiChaquePetitPasCompte.
  ///
  /// In fr, this message translates to:
  /// **'{p0} {p1} à compléter aujourd’hui — chaque petit pas compte.'**
  String aCompleterAujourdhuiChaquePetitPasCompte(Object p0, Object p1);

  /// No description provided for @aCompleterCetteSemaineVousYEtesPresque.
  ///
  /// In fr, this message translates to:
  /// **'{p0} {p1} à compléter cette semaine — vous y êtes presque.'**
  String aCompleterCetteSemaineVousYEtesPresque(Object p0, Object p1);

  /// No description provided for @aCompleterDiciLaFinDuMoisContinuezComme.
  ///
  /// In fr, this message translates to:
  /// **'{p0} {p1} à compléter d’ici la fin du mois — continuez comme ça.'**
  String aCompleterDiciLaFinDuMoisContinuezComme(Object p0, Object p1);

  /// No description provided for @aCompleterSurLanneeUnRythmeRegulierCaPaie.
  ///
  /// In fr, this message translates to:
  /// **'{p0} {p1} à compléter sur l’année — un rythme régulier, ça paie.'**
  String aCompleterSurLanneeUnRythmeRegulierCaPaie(Object p0, Object p1);

  /// No description provided for @tagsCaracteresMax.
  ///
  /// In fr, this message translates to:
  /// **'{p0}/{p1} tags • {p2} caractères max'**
  String tagsCaracteresMax(Object p0, Object p1, Object p2);

  /// No description provided for @caCoince.
  ///
  /// In fr, this message translates to:
  /// **'Ça coince'**
  String get caCoince;

  /// No description provided for @caDeraille.
  ///
  /// In fr, this message translates to:
  /// **'Ça déraille'**
  String get caDeraille;

  /// No description provided for @ecransWeb.
  ///
  /// In fr, this message translates to:
  /// **'Écrans & web'**
  String get ecransWeb;

  /// No description provided for @ecrivezUneNotePourCeCycle.
  ///
  /// In fr, this message translates to:
  /// **'Écrivez une note pour ce cycle…'**
  String get ecrivezUneNotePourCeCycle;

  /// No description provided for @ecrivezUneNotePourCetteJournee.
  ///
  /// In fr, this message translates to:
  /// **'Écrivez une note pour cette journée…'**
  String get ecrivezUneNotePourCetteJournee;

  /// No description provided for @cyclesEchoues.
  ///
  /// In fr, this message translates to:
  /// **'🔴 {p0} cycles échoués'**
  String cyclesEchoues(Object p0);

  /// No description provided for @cyclesReussis.
  ///
  /// In fr, this message translates to:
  /// **'🟢 {p0} cycles réussis'**
  String cyclesReussis(Object p0);

  /// No description provided for @janvier.
  ///
  /// In fr, this message translates to:
  /// **'janvier'**
  String get janvier;

  /// No description provided for @mars.
  ///
  /// In fr, this message translates to:
  /// **'mars'**
  String get mars;

  /// No description provided for @avril.
  ///
  /// In fr, this message translates to:
  /// **'avril'**
  String get avril;

  /// No description provided for @mai.
  ///
  /// In fr, this message translates to:
  /// **'mai'**
  String get mai;

  /// No description provided for @juin.
  ///
  /// In fr, this message translates to:
  /// **'juin'**
  String get juin;

  /// No description provided for @juillet.
  ///
  /// In fr, this message translates to:
  /// **'juillet'**
  String get juillet;

  /// No description provided for @aout.
  ///
  /// In fr, this message translates to:
  /// **'août'**
  String get aout;

  /// No description provided for @septembre.
  ///
  /// In fr, this message translates to:
  /// **'septembre'**
  String get septembre;

  /// No description provided for @octobre.
  ///
  /// In fr, this message translates to:
  /// **'octobre'**
  String get octobre;

  /// No description provided for @novembre.
  ///
  /// In fr, this message translates to:
  /// **'novembre'**
  String get novembre;

  /// No description provided for @lu.
  ///
  /// In fr, this message translates to:
  /// **'Lu'**
  String get lu;

  /// No description provided for @je.
  ///
  /// In fr, this message translates to:
  /// **'Je'**
  String get je;

  /// No description provided for @ve.
  ///
  /// In fr, this message translates to:
  /// **'Ve'**
  String get ve;

  /// No description provided for @sa.
  ///
  /// In fr, this message translates to:
  /// **'Sa'**
  String get sa;

  /// No description provided for @di.
  ///
  /// In fr, this message translates to:
  /// **'Di'**
  String get di;

  /// No description provided for @fevrier2.
  ///
  /// In fr, this message translates to:
  /// **'Février'**
  String get fevrier2;

  /// No description provided for @quotidien2.
  ///
  /// In fr, this message translates to:
  /// **'quotidien'**
  String get quotidien2;

  /// No description provided for @quotidiens.
  ///
  /// In fr, this message translates to:
  /// **'quotidiens'**
  String get quotidiens;

  /// No description provided for @hebdomadaire2.
  ///
  /// In fr, this message translates to:
  /// **'hebdomadaire'**
  String get hebdomadaire2;

  /// No description provided for @hebdomadaires.
  ///
  /// In fr, this message translates to:
  /// **'hebdomadaires'**
  String get hebdomadaires;

  /// No description provided for @mensuel2.
  ///
  /// In fr, this message translates to:
  /// **'mensuel'**
  String get mensuel2;

  /// No description provided for @mensuels.
  ///
  /// In fr, this message translates to:
  /// **'mensuels'**
  String get mensuels;

  /// No description provided for @annuel2.
  ///
  /// In fr, this message translates to:
  /// **'annuel'**
  String get annuel2;

  /// No description provided for @annuels.
  ///
  /// In fr, this message translates to:
  /// **'annuels'**
  String get annuels;

  /// No description provided for @commandement.
  ///
  /// In fr, this message translates to:
  /// **'commandement'**
  String get commandement;

  /// No description provided for @commandements2.
  ///
  /// In fr, this message translates to:
  /// **'commandements'**
  String get commandements2;

  /// No description provided for @langue.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get langue;

  /// No description provided for @francais.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get francais;

  /// No description provided for @anglais.
  ///
  /// In fr, this message translates to:
  /// **'Anglais'**
  String get anglais;

  /// No description provided for @laLangueNaPasPuEtreEnregistree.
  ///
  /// In fr, this message translates to:
  /// **'La langue n’a pas pu être enregistrée.'**
  String get laLangueNaPasPuEtreEnregistree;

  /// No description provided for @jourCourtLundi.
  ///
  /// In fr, this message translates to:
  /// **'L'**
  String get jourCourtLundi;

  /// No description provided for @jourCourtMardi.
  ///
  /// In fr, this message translates to:
  /// **'Ma'**
  String get jourCourtMardi;

  /// No description provided for @jourCourtMercredi.
  ///
  /// In fr, this message translates to:
  /// **'Me'**
  String get jourCourtMercredi;

  /// No description provided for @jourCourtJeudi.
  ///
  /// In fr, this message translates to:
  /// **'J'**
  String get jourCourtJeudi;

  /// No description provided for @jourCourtVendredi.
  ///
  /// In fr, this message translates to:
  /// **'V'**
  String get jourCourtVendredi;

  /// No description provided for @jourCourtSamedi.
  ///
  /// In fr, this message translates to:
  /// **'S'**
  String get jourCourtSamedi;

  /// No description provided for @jourCourtDimanche.
  ///
  /// In fr, this message translates to:
  /// **'D'**
  String get jourCourtDimanche;

  /// No description provided for @erreurEnregistrementNote.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’enregistrer la note. Veuillez réessayer.'**
  String get erreurEnregistrementNote;

  /// No description provided for @notePermissionSave.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde refusée par Firestore. Déployez les règles du dépôt (cycle_notes) : firebase deploy --only firestore:rules'**
  String get notePermissionSave;

  /// No description provided for @notePermissionDelete.
  ///
  /// In fr, this message translates to:
  /// **'Suppression refusée par Firestore. Déployez les règles du dépôt (cycle_notes) : firebase deploy --only firestore:rules'**
  String get notePermissionDelete;

  /// No description provided for @journalTitle.
  ///
  /// In fr, this message translates to:
  /// **'Carnet de bord'**
  String get journalTitle;

  /// No description provided for @journalAddTask.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle tâche'**
  String get journalAddTask;

  /// No description provided for @journalTaskTitle.
  ///
  /// In fr, this message translates to:
  /// **'Que veux-tu accomplir ?'**
  String get journalTaskTitle;

  /// No description provided for @journalTaskHint.
  ///
  /// In fr, this message translates to:
  /// **'Une action concrète pour ta journée'**
  String get journalTaskHint;

  /// No description provided for @journalTaskRequired.
  ///
  /// In fr, this message translates to:
  /// **'Indique une tâche (200 caractères maximum).'**
  String get journalTaskRequired;

  /// No description provided for @journalPlannedFor.
  ///
  /// In fr, this message translates to:
  /// **'Prévue pour le {date}'**
  String journalPlannedFor(String date);

  /// No description provided for @journalOriginalDate.
  ///
  /// In fr, this message translates to:
  /// **'Prévue à l’origine le {date}'**
  String journalOriginalDate(String date);

  /// No description provided for @journalPriority.
  ///
  /// In fr, this message translates to:
  /// **'Priorité du jour'**
  String get journalPriority;

  /// No description provided for @journalPriorityHelp.
  ///
  /// In fr, this message translates to:
  /// **'Un repère visuel, sans modifier le score.'**
  String get journalPriorityHelp;

  /// No description provided for @journalToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd’hui'**
  String get journalToday;

  /// No description provided for @journalTomorrow.
  ///
  /// In fr, this message translates to:
  /// **'Demain'**
  String get journalTomorrow;

  /// No description provided for @journalCalendar.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une journée'**
  String get journalCalendar;

  /// No description provided for @journalPreviousDay.
  ///
  /// In fr, this message translates to:
  /// **'Jour précédent'**
  String get journalPreviousDay;

  /// No description provided for @journalNextDay.
  ///
  /// In fr, this message translates to:
  /// **'Jour suivant'**
  String get journalNextDay;

  /// No description provided for @journalAccomplishments.
  ///
  /// In fr, this message translates to:
  /// **'Mes accomplissements'**
  String get journalAccomplishments;

  /// No description provided for @journalCompletedCount.
  ///
  /// In fr, this message translates to:
  /// **'{done, plural, =0{0 tâche accomplie} =1{{done} tâche accomplie} other{{done} tâches accomplies}} sur {total}'**
  String journalCompletedCount(int done, int total);

  /// No description provided for @journalScoreHelp.
  ///
  /// In fr, this message translates to:
  /// **'Chaque tâche a le même poids. Le bilan du jour garde la trace de tes engagements, même si une tâche est reportée. Supprimer ou replanifier une tâche aujourd’hui la retire du score d’aujourd’hui.'**
  String get journalScoreHelp;

  /// No description provided for @journalNoScore.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de score'**
  String get journalNoScore;

  /// No description provided for @journalCelebrate.
  ///
  /// In fr, this message translates to:
  /// **'Tu as tenu tous tes engagements. Savoure le travail accompli !'**
  String get journalCelebrate;

  /// No description provided for @journalProgress.
  ///
  /// In fr, this message translates to:
  /// **'Chaque tâche accomplie fait avancer ta journée.'**
  String get journalProgress;

  /// No description provided for @journalStart.
  ///
  /// In fr, this message translates to:
  /// **'Un premier pas suffit pour lancer ta journée.'**
  String get journalStart;

  /// No description provided for @journalPending.
  ///
  /// In fr, this message translates to:
  /// **'À accomplir · {count}'**
  String journalPending(int count);

  /// No description provided for @journalDone.
  ///
  /// In fr, this message translates to:
  /// **'Accomplies · {count}'**
  String journalDone(int count);

  /// No description provided for @journalLate.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 jour de retard} other{{count} jours de retard}}'**
  String journalLate(int count);

  /// No description provided for @journalCompletedToday.
  ///
  /// In fr, this message translates to:
  /// **'Accomplie aujourd’hui'**
  String get journalCompletedToday;

  /// No description provided for @journalCompletedDay.
  ///
  /// In fr, this message translates to:
  /// **'Accomplie ce jour-là'**
  String get journalCompletedDay;

  /// No description provided for @journalCarryHint.
  ///
  /// In fr, this message translates to:
  /// **'Les tâches reportables inachevées passent au lendemain, sans doublon. Les autres restent dans le bilan du jour prévu.'**
  String get journalCarryHint;

  /// No description provided for @journalFutureHint.
  ///
  /// In fr, this message translates to:
  /// **'Les tâches reportables en cours sont affichées à titre prévisionnel. Termine-les aujourd’hui et elles ne seront plus à reprendre demain.'**
  String get journalFutureHint;

  /// No description provided for @journalPastHint.
  ///
  /// In fr, this message translates to:
  /// **'Le bilan de tes engagements pour cette journée.'**
  String get journalPastHint;

  /// No description provided for @journalEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'De la place pour tes projets'**
  String get journalEmptyTitle;

  /// No description provided for @journalEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Prévois quelques actions réalistes et retrouve ici la satisfaction de les accomplir.'**
  String get journalEmptyBody;

  /// No description provided for @journalEmptyPast.
  ///
  /// In fr, this message translates to:
  /// **'Rien de consigné ce jour-là'**
  String get journalEmptyPast;

  /// No description provided for @journalEditTask.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la tâche'**
  String get journalEditTask;

  /// No description provided for @journalReschedule.
  ///
  /// In fr, this message translates to:
  /// **'Replanifier'**
  String get journalReschedule;

  /// No description provided for @journalRemoved.
  ///
  /// In fr, this message translates to:
  /// **'Tâche supprimée du planning.'**
  String get journalRemoved;

  /// No description provided for @journalCompletedFeedback.
  ///
  /// In fr, this message translates to:
  /// **'Un engagement tenu. Bien joué !'**
  String get journalCompletedFeedback;

  /// No description provided for @journalAllDoneFeedback.
  ///
  /// In fr, this message translates to:
  /// **'Tout est accompli pour aujourd’hui !'**
  String get journalAllDoneFeedback;

  /// No description provided for @journalError.
  ///
  /// In fr, this message translates to:
  /// **'Le carnet n’a pas pu être mis à jour. Réessaie dans un instant.'**
  String get journalError;

  /// No description provided for @journalLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Le carnet est momentanément indisponible. Tes données restent conservées.'**
  String get journalLoadError;

  /// No description provided for @journalRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get journalRetry;

  /// No description provided for @journalBalance.
  ///
  /// In fr, this message translates to:
  /// **'Bilan de la journée'**
  String get journalBalance;

  /// No description provided for @journalReviewAction.
  ///
  /// In fr, this message translates to:
  /// **'Mon bilan'**
  String get journalReviewAction;

  /// No description provided for @journalFeeling.
  ///
  /// In fr, this message translates to:
  /// **'Comment je me sens'**
  String get journalFeeling;

  /// No description provided for @journalMoodDifficult.
  ///
  /// In fr, this message translates to:
  /// **'Difficile'**
  String get journalMoodDifficult;

  /// No description provided for @journalMoodMixed.
  ///
  /// In fr, this message translates to:
  /// **'Mitigé'**
  String get journalMoodMixed;

  /// No description provided for @journalMoodSatisfied.
  ///
  /// In fr, this message translates to:
  /// **'Satisfait'**
  String get journalMoodSatisfied;

  /// No description provided for @journalReflection.
  ///
  /// In fr, this message translates to:
  /// **'Ce que je retiens'**
  String get journalReflection;

  /// No description provided for @journalReflectionHint.
  ///
  /// In fr, this message translates to:
  /// **'Une réussite, une difficulté ou une idée pour demain…'**
  String get journalReflectionHint;

  /// No description provided for @journalReflectionHelp.
  ///
  /// In fr, this message translates to:
  /// **'Facultatif. Prends un instant pour reconnaître ce que tu as accompli.'**
  String get journalReflectionHelp;

  /// No description provided for @journalReflectionSaved.
  ///
  /// In fr, this message translates to:
  /// **'Bilan enregistré.'**
  String get journalReflectionSaved;

  /// No description provided for @journalWeek.
  ///
  /// In fr, this message translates to:
  /// **'Mes 7 derniers jours'**
  String get journalWeek;

  /// No description provided for @journalWeekDay.
  ///
  /// In fr, this message translates to:
  /// **'{date} : {score} %'**
  String journalWeekDay(String date, int score);

  /// No description provided for @journalWeekEmpty.
  ///
  /// In fr, this message translates to:
  /// **'{date} : aucune tâche'**
  String journalWeekEmpty(String date);

  /// No description provided for @journalReorderHint.
  ///
  /// In fr, this message translates to:
  /// **'Appui long pour réorganiser tes tâches.'**
  String get journalReorderHint;

  /// No description provided for @journalSignIn.
  ///
  /// In fr, this message translates to:
  /// **'Connecte-toi pour retrouver ton carnet et préparer ta journée.'**
  String get journalSignIn;

  /// No description provided for @journalReadOnly.
  ///
  /// In fr, this message translates to:
  /// **'Les journées passées restent inchangées.'**
  String get journalReadOnly;

  /// No description provided for @journalDeleteTask.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la tâche'**
  String get journalDeleteTask;

  /// No description provided for @journalTaskActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions de la tâche'**
  String get journalTaskActions;

  /// No description provided for @journalFutureScore.
  ///
  /// In fr, this message translates to:
  /// **'Journée en préparation'**
  String get journalFutureScore;

  /// No description provided for @journalSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get journalSave;

  /// No description provided for @journalCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get journalCancel;

  /// No description provided for @journalUndo.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get journalUndo;

  /// No description provided for @journalSignInAction.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get journalSignInAction;

  /// No description provided for @hiddenCommandsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Commandements masqués ({count})'**
  String hiddenCommandsTitle(int count);

  /// No description provided for @hiddenCommandsHelp.
  ///
  /// In fr, this message translates to:
  /// **'Ces commandements sont en pause. Leur historique est conservé et ils ne déclenchent plus de rappels. Les filtres et la recherche s’appliquent aussi à cette section.'**
  String get hiddenCommandsHelp;

  /// No description provided for @hideCommandTitle.
  ///
  /// In fr, this message translates to:
  /// **'Masquer ce commandement ?'**
  String get hideCommandTitle;

  /// No description provided for @hideCommandMessage.
  ///
  /// In fr, this message translates to:
  /// **'Il sera mis en pause sans date de reprise et retiré des affichages habituels. Tu le retrouveras dans « Commandements masqués », avec tout son historique.'**
  String get hideCommandMessage;

  /// No description provided for @hideCommandAction.
  ///
  /// In fr, this message translates to:
  /// **'Masquer le commandement'**
  String get hideCommandAction;

  /// No description provided for @showCommandTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réafficher ce commandement ?'**
  String get showCommandTitle;

  /// No description provided for @showCommandMessage.
  ///
  /// In fr, this message translates to:
  /// **'Il retrouvera sa place dans la liste et restera en pause. Tu pourras le reprendre quand tu le souhaites.'**
  String get showCommandMessage;

  /// No description provided for @showCommandAction.
  ///
  /// In fr, this message translates to:
  /// **'Réafficher'**
  String get showCommandAction;

  /// No description provided for @commandHiddenFeedback.
  ///
  /// In fr, this message translates to:
  /// **'Commandement masqué et mis en pause.'**
  String get commandHiddenFeedback;

  /// No description provided for @commandShownFeedback.
  ///
  /// In fr, this message translates to:
  /// **'Commandement réaffiché, toujours en pause.'**
  String get commandShownFeedback;

  /// No description provided for @hiddenCommandStatus.
  ///
  /// In fr, this message translates to:
  /// **'Masqué · en pause'**
  String get hiddenCommandStatus;

  /// No description provided for @onboardingJournalTitle.
  ///
  /// In fr, this message translates to:
  /// **'Savoure le travail accompli'**
  String get onboardingJournalTitle;

  /// No description provided for @onboardingJournalBody.
  ///
  /// In fr, this message translates to:
  /// **'Prépare ta journée dans ton carnet de bord. Coche tes tâches, retrouve celles à reprendre et prends un instant pour apprécier tes avancées.'**
  String get onboardingJournalBody;

  /// No description provided for @onboardingJournalQuote.
  ///
  /// In fr, this message translates to:
  /// **'Chaque petit pas mérite d’être reconnu.'**
  String get onboardingJournalQuote;

  /// No description provided for @journalReportable.
  ///
  /// In fr, this message translates to:
  /// **'Reportable'**
  String get journalReportable;

  /// No description provided for @journalReportableHelp.
  ///
  /// In fr, this message translates to:
  /// **'Si elle n’est pas accomplie, la tâche passe automatiquement au lendemain. Sinon, elle reste en échec dans le bilan du jour prévu.'**
  String get journalReportableHelp;

  /// No description provided for @journalFailed.
  ///
  /// In fr, this message translates to:
  /// **'Non accomplie · non reportable'**
  String get journalFailed;

  /// No description provided for @journalPlannedToday.
  ///
  /// In fr, this message translates to:
  /// **'Prévue pour aujourd’hui'**
  String get journalPlannedToday;

  /// No description provided for @commandBestStreak.
  ///
  /// In fr, this message translates to:
  /// **'Record de série : {count, plural, =0{0 succès} =1{1 succès} other{{count} succès}} consécutifs'**
  String commandBestStreak(int count);

  /// No description provided for @resistanceRecordActive.
  ///
  /// In fr, this message translates to:
  /// **'Série record en cours'**
  String get resistanceRecordActive;

  /// No description provided for @journalUnfinished.
  ///
  /// In fr, this message translates to:
  /// **'Non accomplies · {count}'**
  String journalUnfinished(int count);

  /// No description provided for @journalTaskUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Tâche modifiée.'**
  String get journalTaskUpdated;

  /// No description provided for @relapseNoteAction.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter ou modifier une note'**
  String get relapseNoteAction;

  /// No description provided for @relapseNoteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Note de rechute'**
  String get relapseNoteTitle;

  /// No description provided for @relapseNoteHint.
  ///
  /// In fr, this message translates to:
  /// **'Ce qui s’est passé, ce que tu souhaites retenir…'**
  String get relapseNoteHint;

  /// No description provided for @relapseNoteSaved.
  ///
  /// In fr, this message translates to:
  /// **'Note enregistrée.'**
  String get relapseNoteSaved;

  /// No description provided for @relapseNoteRemoved.
  ///
  /// In fr, this message translates to:
  /// **'Note supprimée.'**
  String get relapseNoteRemoved;

  /// No description provided for @relapseNoteError.
  ///
  /// In fr, this message translates to:
  /// **'La note n’a pas pu être enregistrée. Réessaie dans un instant.'**
  String get relapseNoteError;

  /// No description provided for @journalCalendarTitle.
  ///
  /// In fr, this message translates to:
  /// **'Calendrier du carnet'**
  String get journalCalendarTitle;

  /// No description provided for @journalCalendarSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Réussi'**
  String get journalCalendarSuccess;

  /// No description provided for @journalCalendarFailure.
  ///
  /// In fr, this message translates to:
  /// **'Incomplet'**
  String get journalCalendarFailure;

  /// No description provided for @journalCalendarEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune tâche'**
  String get journalCalendarEmpty;

  /// No description provided for @journalCalendarCurrent.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get journalCalendarCurrent;

  /// No description provided for @journalCalendarPlanned.
  ///
  /// In fr, this message translates to:
  /// **'Planifié'**
  String get journalCalendarPlanned;

  /// No description provided for @journalCalendarDay.
  ///
  /// In fr, this message translates to:
  /// **'{date} : {status}, {done} sur {total} accomplis'**
  String journalCalendarDay(String date, String status, int done, int total);

  /// No description provided for @journalCalendarHelp.
  ///
  /// In fr, this message translates to:
  /// **'Vert : tous les engagements tenus. Rouge : une journée passée avec des tâches inachevées.'**
  String get journalCalendarHelp;

  /// No description provided for @journalPastNoScore.
  ///
  /// In fr, this message translates to:
  /// **'Journée sans engagements'**
  String get journalPastNoScore;

  /// No description provided for @journalPastEmptyHint.
  ///
  /// In fr, this message translates to:
  /// **'Aucune tâche enregistrée : cette journée ne compte ni comme une réussite ni comme un échec.'**
  String get journalPastEmptyHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
