Quick start for the localization (l10n) scripts
===============================================

The following assumes that all of these are in present in
$FG_ROOT/Translations:
  - the default translation (default/*.xml);
  - the legacy FlightGear XML localization files (<language_code>/*.xml);
  - except for 'fg-convert-translation-files' which creates them, existing
    XLIFF 1.2 files (<language_code>/FlightGear-nonQt.xlf).

Note: the legacy FlightGear XML localization files are only needed by
      'fg-convert-translation-files' when migrating to the XLIFF format. The
      other scripts only need the default translation and obviously, for
      'fg-update-translation-files', the current XLIFF files.

To get the initial XLIFF files (generated from the default translation in
$FG_ROOT/Translations/default as well as the legacy FlightGear XML
localization files in $FG_ROOT/Translations/<language_code>):

  languages="de en_US es fr it nl pl pt zh_CN"

  # Your shell must expand $languages as several words. POSIX shell does that,
  # but not zsh for instance. Otherwise, don't use a shell variable.
  fg-convert-translation-files --transl-dir="$FG_ROOT/Translations" $languages

  # Add strings found in the default translation but missing in the legacy FG
  # XML l10n files
  fg-update-translation-files --transl-dir="$FG_ROOT/Translations" \
                              merge-new-master $languages

When master strings[1] have changed (in a large sense, i.e.: strings added,
modified or removed, or categories added or removed[2]):

  fg-update-translation-files --transl-dir="$FG_ROOT/Translations" \
                              merge-new-master $languages

To remove unused translated strings (not to be done too often in my opinion):

  fg-update-translation-files --transl-dir="$FG_ROOT/Translations" \
                              remove-unused $languages

(you may replace 'remove-unused' with 'mark-unused' to just mark the strings
as not-to-be-translated, however 'merge-new-master' presented above already
does that)

To create skeleton translations for new languages (e.g., for fr_BE, en_AU and
ca):

  1) Check (add if necessary) that flightgear/meta/i18n.py knows the plural
     forms used in the new languages. This is done by editing PLURAL_FORMS
     towards the top of this i18n.py file (very easy). If the existing entry
     for, e.g., "zh" is sufficient for zh_TW or zh_HK, just let "zh" handle
     them: it will be tried as fallback if there is no perfect match on
     language and territory.

  2) Run a command such as:

       fg-new-translations --transl-dir="$FG_ROOT/Translations" fr_BE en_AU ca

     (if you do this for only one language at a time, you can use the -o
     option to precisely control where the output goes, otherwise
     fg-new-translations chooses an appropriate place based on the value
     specified for --transl-dir)

fg-convert-translation-files, fg-update-translation-files and
fg-new-translations all support the --help option for more detailed
information.


Footnotes
---------

  [1] Strings in the default translation.

  [2] Only empty categories are removed by this command. An obsolete category
      can be made empty by manual editing (easy, just locate the right
      <group>) or this way:

        fg-update-translation-files --transl-dir=... mark-unused
        fg-update-translation-files --transl-dir=... remove-unused

      (note that this will remove *all* strings marked as unused in the first
      step, not only those in some particular category!)
