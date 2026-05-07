import 'dart:convert';

void main() {
  //zad1/A
  String jsonText_A = '''
  [1, 5, 8, 3, 2]
  ''';

  final data_A = jsonDecode(jsonText_A);

  int suma = 0;

  for (var liczba in data_A) {
    print(liczba);
    suma += liczba as int;
  }

  print("Suma: $suma");
  //zad1/B
  String jsonText_B = '''
  {
    "group": "Dart",
    "students": ["Ola", "Adam", "Kasia"]
  }
  ''';

  final data_B = jsonDecode(jsonText_B);

  print("Grupa: ${data_B["group"]}");

  for (var student in data_B["students"]) {
    print(student);
  }


  //zad1/C
  String jsonText_C = '''
  {
    "product": {
      "name": "Laptop",
      "price": 3500
    }
  }
  ''';

  final data_C = jsonDecode(jsonText_C);

  print("Produkt: ${data_C["product"]["name"]}");
  print("Cena: ${data_C["product"]["price"]}");
}