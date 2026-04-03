defmodule Localize.PersonName.Names do
  @moduledoc false

  def known_names do
    Map.keys(names())
  end

  def random do
    random =
      known_names()
      |> Enum.random()

    names()[random]
  end

  def names do
    alias Localize.PersonName

    {:ok, en_aq} = Localize.validate_locale("en-AQ")
    {:ok, fr_aq} = Localize.validate_locale("fr-AQ")
    {:ok, de_aq} = Localize.validate_locale("de-AQ")
    {:ok, ko_aq} = Localize.validate_locale("ko-AQ")
    {:ok, es_aq} = Localize.validate_locale("es-AQ")
    {:ok, pt_aq} = Localize.validate_locale("pt-AQ")
    {:ok, ja_aq} = Localize.validate_locale("ja-AQ")
    {:ok, he_aq} = Localize.validate_locale("he-AQ")
    {:ok, zh_aq} = Localize.validate_locale("zh-AQ")
    {:ok, cs_aq} = Localize.validate_locale("cs-AQ")
    {:ok, id_aq} = Localize.validate_locale("id-AQ")
    {:ok, ca_aq} = Localize.validate_locale("ca-AQ")

    {:ok, es_mx} = Localize.validate_locale("es-MX")
    {:ok, es_us} = Localize.validate_locale("es-US")
    {:ok, de} = Localize.validate_locale("de")

    %{
      mary: %PersonName{
        given_name: "Mary Sue",
        other_given_names: "Hamish",
        surname: "Watson",
        locale: en_aq
      },
      kathe: %PersonName{
        given_name: "Käthe",
        surname: "Müller",
        locale: ja_aq
      },
      irene: %PersonName{
        given_name: "Irene",
        surname: "Adler",
        locale: en_aq
      },
      sinbad: %PersonName{
        given_name: "Sinbad",
        locale: ja_aq
      },
      zendaya: %PersonName{
        given_name: "Zendaya",
        locale: en_aq
      },
      jn: %PersonName{
        given_name: "Jean-Nicolas",
        informal_given_name: "Nico",
        other_given_names: "Louis Marcel",
        surname_prefix: "de",
        surname: "Bouchart",
        generation: "fils",
        locale: fr_aq
      },
      adele: %PersonName{
        given_name: "Adèle",
        locale: fr_aq
      },
      iris: %PersonName{
        given_name: "Iris",
        surname: "Falke",
        locale: de
      },
      paul: %PersonName{
        title: "Dr.",
        given_name: "Paul",
        informal_given_name: "Pauli",
        other_given_names: "Vinzent",
        surname_prefix: "von",
        surname: "Fischer",
        generation: "jr.",
        credentials: "MdB",
        locale: de_aq
      },
      adelaide: %PersonName{
        given_name: "Adélaïde",
        surname: "Lemaître",
        locale: ko_aq
      },
      pablo: %PersonName{
        title: "Sr.",
        given_name: "Miguel Ángel",
        informal_given_name: "Migue",
        other_given_names: "Juan Antonio",
        surname: "Pablo",
        other_surnames: "Pérez",
        generation: "II",
        locale: es_aq
      },
      rosa: %PersonName{
        given_name: "Rosa",
        other_given_names: "María",
        surname: "Ruiz",
        locale: es_aq
      },
      maria: %PersonName{
        given_name: "Maria",
        surname: "Silva",
        locale: pt_aq
      },
      ichiro: %PersonName{
        given_name: "一郎",
        surname: "安藤",
        locale: ja_aq
      },
      jonathan: %PersonName{
        given_name: "יונתן",
        other_given_names: "חיים",
        surname: "כהן",
        locale: he_aq
      },
      pretty: %PersonName{
        given_name: "俊年",
        other_given_names: "杰思",
        surname: "陈",
        locale: zh_aq
      },
      virtue: %PersonName{
        title: "先生",
        given_name: "德威",
        informal_given_name: "小德",
        other_given_names: "东升",
        surname: "彭",
        generation: "小",
        credentials: "议员",
        locale: zh_aq
      },
      ada_zh: %PersonName{
        title: "教授",
        given_name: "艾达·科妮莉亚",
        informal_given_name: "尼尔",
        other_given_names: "塞萨尔·马丁",
        surname_prefix: "冯",
        surname: "布鲁赫",
        generation: "小",
        credentials: "博士",
        locale: en_aq
      },
      ada: %PersonName{
        title: "Prof. Dr.",
        given_name: "Ada Cornelia",
        informal_given_name: "Neele",
        other_given_names: "César Martín",
        surname_prefix: "von",
        surname: "Brühl",
        other_surnames: "González Domingo",
        generation: "Jr",
        credentials: "MD DDS",
        locale: ja_aq
      },
      juan: %PersonName{
        given_name: "Juan",
        other_given_names: "Luis Antonio",
        surname: "Rodríguez Ruiz",
        locale: es_mx
      },
      marcelo: %PersonName{
        title: "Sr.",
        given_name: "Marcelo Miguel",
        informal_given_name: "Marce",
        other_given_names: "Javier Ariel",
        surname: "Romero",
        other_surnames: "Pérez",
        generation: "Júnior",
        credentials: "Miembro del Parlamento",
        locale: es_mx
      },
      lucia: %PersonName{
        given_name: "Lucía",
        surname: "García Pérez",
        locale: es_us
      },
      jana: %PersonName{
        given_name: "Jana",
        surname: "Nováková",
        locale: cs_aq
      },
      kate: %PersonName{
        given_name: "Kate",
        surname: "Smith",
        locale: ko_aq
      },
      alexandra: %PersonName{
        title: "paní",
        given_name: "Alexandra",
        informal_given_name: "Saša",
        other_given_names: "Zuzana",
        surname: "Machová",
        other_surnames: "Ondřejová",
        generation: "st.",
        credentials: "Ph.D.",
        locale: cs_aq
      },
      dwi: %PersonName{
        title: "Bapak",
        given_name: "Dwi Putro",
        informal_given_name: "Dwi",
        other_given_names: "bin",
        surname: "Adinata",
        credentials: "MP",
        locale: id_aq
      },
      gal: %PersonName{
        given_name: "Gal·la",
        surname: "Roig",
        locale: ca_aq
      },
      jacqueline: %PersonName{
        given_name: "Jacqueline",
        surname: "Beauchêne",
        locale: ko_aq
      },
      josep: %PersonName{
        title: "Sr.",
        given_name: "Josep Antoni",
        informal_given_name: "Pep",
        other_given_names: "Carles Joan",
        surname: "Lloret",
        other_surnames: "Palol",
        generation: "II",
        credentials: "Excm",
        locale: ca_aq
      },
      marie_agnes: %PersonName{
        given_name: "Marie-Agnès",
        other_given_names: "Suzanne",
        surname: "Gilot",
        locale: fr_aq
      },
      cornelia: %PersonName{
        title: "Καθ. δρ.",
        given_name: "Άντα Κορνέλια",
        informal_given_name: "Νιλ",
        other_given_names: "Σέσαρ Μαρτίν",
        surname_prefix: "φον",
        surname: "Μπριλ",
        other_surnames: "Palol",
        generation: "Τζούνιορ",
        credentials: "Δρ.Ι. Δρ.Χ.Ο",
        locale: ja_aq
      }
    }
  end
end
