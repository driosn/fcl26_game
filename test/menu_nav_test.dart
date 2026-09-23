import 'package:fcl_26_game/src/ui/menu_nav.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('next and prev wrap around the bound actions', () {
    final nav = MenuNavController();
    addTearDown(nav.dispose);

    final hits = <String>[];
    nav.bind([() => hits.add('a'), () => hits.add('b'), () => hits.add('c')]);

    expect(nav.index.value, 0);
    nav.next();
    nav.next();
    expect(nav.index.value, 2);
    nav.next();
    expect(nav.index.value, 0);
    nav.prev();
    expect(nav.index.value, 2);

    nav.activate();
    expect(hits, ['c']);
  });

  test('activate is a no-op before bind', () {
    final nav = MenuNavController();
    addTearDown(nav.dispose);
    nav.next();
    nav.activate();
    expect(nav.hasActions, isFalse);
  });
}
