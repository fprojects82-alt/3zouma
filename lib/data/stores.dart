import 'settings.dart';

/// Links into grocery apps. None of these stores has a public ordering API
/// yet, so the app copies the list and opens the store, using a search link
/// where the store has one. Partner basket links replace this later.
class StoreLinks {
  static String name(GroceryStore s, bool arabic) => switch (s) {
        GroceryStore.talabat => arabic ? 'طلبات' : 'Talabat',
        GroceryStore.carrefour => arabic ? 'كارفور' : 'Carrefour',
        GroceryStore.breadfast => arabic ? 'بريدفاست' : 'Breadfast',
      };

  /// A link that opens the store, searching for [query] when supported.
  static Uri open(GroceryStore s, {String? query}) {
    switch (s) {
      case GroceryStore.carrefour:
        if (query != null && query.isNotEmpty) {
          return Uri.https('www.carrefouregypt.com', '/mafegy/en/search', {'keyword': query});
        }
        return Uri.https('www.carrefouregypt.com', '/mafegy/en/');
      case GroceryStore.talabat:
        return Uri.https('www.talabat.com', '/egypt/groceries');
      case GroceryStore.breadfast:
        return Uri.https('www.breadfast.com', '/');
    }
  }

  static bool supportsSearch(GroceryStore s) => s == GroceryStore.carrefour;
}
