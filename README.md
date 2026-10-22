# Ozouma (عزومة)

Hands-free voice cooking for Egyptian and MENA home cooks, in Egyptian Arabic and English.

## What is in this first build

- **Language first:** Arabic (right to left, Eastern Arabic numerals) or English, chosen on first launch and changeable in Profile.
- **Recipes:** six curated Egyptian recipes (koshari, molokhia, shakshuka, lentil soup, basbousa, ful) with servings scaling.
- **Cooking mode:** one big step at a time, screen kept awake, tap either side to move.
  - Voice commands such as "next", "repeat", "how long left", "اللي بعده", "عيدي", "فاضل قد إيه".
  - Steps are read aloud.
- **Timers:** detected from the step text in both languages (for example "نص ساعة", "ساعة ونص", "10 to 12 minutes").
  - A 3 second count-in before each timer starts.
  - Timers keep running while you move to other steps.
  - The ring turns red in the last 10%, then an alarm sounds.
- **Add a recipe:** paste text from TikTok, Instagram or WhatsApp and it is split into ingredients and steps.
- **My kitchen:** tick what you have to see what you can cook. A shopping list can be copied and opened in Talabat, Carrefour or Breadfast.

## Run it

You need Flutter 3.24 or newer.

```bash
./scripts/setup_platforms.sh   # creates android/ ios/ web/ and adds mic + speech permissions
flutter pub get
flutter run
```

The platform folders are generated rather than committed, so run the setup script once after cloning.

## Checks

```bash
flutter analyze
flutter test
```

GitHub Actions runs both on every push and builds a debug APK, which you can download from the run's artifacts as `ozouma-debug-apk`.

## Project layout

```
lib/
  core/      theme, strings (Arabic and English), numerals, app scope
  models/    recipe, ingredient, step
  cooking/   duration parser, voice commands, cooking session, speech
  import/    pasted recipe parser
  data/      settings, recipes, pantry and shopping list, store links
  ui/        screens and shared widgets
assets/
  brand/     logo
  data/      recipes.json, ingredients.json
```

Recipes live in `assets/data/recipes.json`. Each step has its text in both languages, and a test checks that the timers in the two languages agree.
