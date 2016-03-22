﻿#Использовать cmdline
#Использовать logos
#Использовать tempfiles
#Использовать asserts
#Использовать v8runner
#Использовать strings

Перем Лог;
Перем КодВозврата;
Перем мВозможныеКоманды;
Перем ЭтоWindows;

Функция ПолучитьВерсию() Экспорт
	
	Версия = "2.0.0";
		
	Возврат "v" + Версия;
		
КонецФункции

Функция ВозможныеКоманды()
	
	Если мВозможныеКоманды = Неопределено Тогда
		мВозможныеКоманды = Новый Структура;
		мВозможныеКоманды.Вставить("Декомпилировать", "--decompile");
		мВозможныеКоманды.Вставить("Помощь", "--help");
		мВозможныеКоманды.Вставить("ОбработатьИзмененияИзГит", "--git-precommit");
		мВозможныеКоманды.Вставить("Компилировать", "--compile");
	КонецЕсли;
	
	Возврат мВозможныеКоманды;
	
КонецФункции

Функция ЗапускВКоманднойСтроке()
	Лог_cmdline = Логирование.ПолучитьЛог("oscript.lib.cmdline");
	Лог_cmdline.УстановитьУровень(УровниЛога.Отладка);
	ВыводПоУмолчанию = Новый ВыводЛогаВКонсоль();
	Лог_cmdline.ДобавитьСпособВывода(ВыводПоУмолчанию);
	
	Аппендер = Новый ВыводЛогаВФайл();
	Аппендер.ОткрытьФайл(ОбъединитьПути(КаталогПроекта(), ИмяСкрипта()+".cmdline.log"));
	Лог_cmdline.ДобавитьСпособВывода(Аппендер);
	
	КодВозврата = 0;
	
	Если ТекущийСценарий().Источник <> СтартовыйСценарий().Источник Тогда
		Возврат Ложь;
	КонецЕсли;
	
	Лог.Информация("precommit1c " + ПолучитьВерсию() + Символы.ПС);
	
	Попытка
	
		Парсер = Новый ПарсерАргументовКоманднойСтроки();
		
		ДобавитьОписаниеКомандыДекомпилировать(Парсер);
		ДобавитьОписаниеКомандыПомощь(Парсер);
		ДобавитьОписаниеКомандыИзмененияПоЖурналуГит(Парсер);
		ДобавитьОписаниеКомандыКомпилировать(Парсер);

		Аргументы = Парсер.РазобратьКоманду(АргументыКоманднойСтроки);
		Лог.Отладка("ТипЗнч(Аргументы)= "+ТипЗнч(Аргументы));
		Если Аргументы = Неопределено Тогда
			ВывестиСправку();
			Возврат Истина;
		КонецЕсли;

		Команда = Аргументы.Команда;
		Лог.Отладка("Передана команда: "+Команда);
		Для Каждого Параметр Из Аргументы.ЗначенияПараметров Цикл
			Лог.Отладка(Параметр.Ключ + " = " + Параметр.Значение);
		КонецЦикла;
		
		Если Команда = ВозможныеКоманды().Декомпилировать Тогда
			Декомпилировать(Аргументы.ЗначенияПараметров["ПутьВходящихДанных"], Аргументы.ЗначенияПараметров["ВыходнойКаталог"]);
		ИначеЕсли Команда = ВозможныеКоманды().Помощь Тогда
			ВывестиСправку();
		ИначеЕсли Команда = ВозможныеКоманды().ОбработатьИзмененияИзГит Тогда
			ОбработатьИзмененияИзГит(Аргументы.ЗначенияПараметров["ВыходнойКаталог"], Аргументы.ЗначенияПараметров["--remove-orig-bin-files"]);
		ИначеЕсли Команда = ВозможныеКоманды().Компилировать Тогда
			Компилировать(
				Аргументы.ЗначенияПараметров["ПутьВходящихДанных"], 
				Аргументы.ЗначенияПараметров["ВыходнойКаталог"], 
				Аргументы.ЗначенияПараметров["--recursive"]
			);
		КонецЕсли;
		
	Исключение
		Лог.Ошибка(ОписаниеОшибки());
		КодВозврата = 1;
	КонецПопытки;
	
	ВременныеФайлы.Удалить();

	Возврат Истина;
	
КонецФункции

Процедура ДобавитьОписаниеКомандыДекомпилировать(Знач Парсер)
	ОписаниеКоманды = Парсер.ОписаниеКоманды(ВозможныеКоманды().Декомпилировать);
	Парсер.ДобавитьПозиционныйПараметрКоманды(ОписаниеКоманды, "ПутьВходящихДанных");
	Парсер.ДобавитьПозиционныйПараметрКоманды(ОписаниеКоманды, "ВыходнойКаталог");
	Парсер.ДобавитьКоманду(ОписаниеКоманды);
КонецПроцедуры

Процедура ДобавитьОписаниеКомандыПомощь(Знач Парсер)
	ОписаниеКоманды = Парсер.ОписаниеКоманды(ВозможныеКоманды().Помощь);
	Парсер.ДобавитьКоманду(ОписаниеКоманды);
КонецПроцедуры

Процедура ДобавитьОписаниеКомандыИзмененияПоЖурналуГит(Знач Парсер)
	
	ОписаниеКоманды = Парсер.ОписаниеКоманды(ВозможныеКоманды().ОбработатьИзмененияИзГит);
	Парсер.ДобавитьПозиционныйПараметрКоманды(ОписаниеКоманды, "ВыходнойКаталог");
	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, "--remove-orig-bin-files");
	Парсер.ДобавитьКоманду(ОписаниеКоманды);
	
КонецПроцедуры

Процедура ДобавитьОписаниеКомандыКомпилировать(Знач Парсер)
	ОписаниеКоманды = Парсер.ОписаниеКоманды(ВозможныеКоманды().Компилировать);
	Парсер.ДобавитьПозиционныйПараметрКоманды(ОписаниеКоманды, "ПутьВходящихДанных");
	Парсер.ДобавитьПозиционныйПараметрКоманды(ОписаниеКоманды, "ВыходнойКаталог");
	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, "--recursive");
	Парсер.ДобавитьКоманду(ОписаниеКоманды);
КонецПроцедуры

Процедура Инициализация()
	СистемнаяИнформация = Новый СистемнаяИнформация;
	ЭтоWindows = Найти(ВРег(СистемнаяИнформация.ВерсияОС), "WINDOWS") > 0;

	Лог = Логирование.ПолучитьЛог("oscript.app.v8files-extractor");
	//Лог.УстановитьУровень(УровниЛога.Отладка);
	
	ВыводПоУмолчанию = Новый ВыводЛогаВКонсоль();
	Лог.ДобавитьСпособВывода(ВыводПоУмолчанию);

	Аппендер = Новый ВыводЛогаВФайл();
	Аппендер.ОткрытьФайл(ОбъединитьПути(КаталогПроекта(), ИмяСкрипта()+".log"));
	Лог.ДобавитьСпособВывода(Аппендер);
КонецПроцедуры


/////////////////////////////////////////////////////////////////////////////
// РЕАЛИЗАЦИЯ КОМАНД

Процедура Декомпилировать(Знач Путь, Знач КаталогВыгрузки) Экспорт
	Файл = Новый Файл(Путь);
	Если Файл.ЭтоКаталог() Тогда
		РазобратьКаталог(Файл, КаталогВыгрузки, Файл.ПолноеИмя);
	Иначе
		РазобратьФайл(Файл, КаталогВыгрузки, Файл.Путь);
	КонецЕсли;
КонецПроцедуры

Процедура РазобратьКаталог(Знач ОбъектКаталога, Знач КаталогВыгрузки, Знач КаталогКорень) Экспорт
	ПутьКаталога = ОбъектКаталога.ПолноеИмя;

	ОтносительныйПутьКаталога = ПолучитьОтносительныйПутьФайла(КаталогКорень, ПутьКаталога);
	ОтносительныйПутьКаталога = ?(ПустаяСтрока(ОтносительныйПутьКаталога), ПутьКаталога, ОтносительныйПутьКаталога);
	Лог.Информация(СтрШаблон("Подготовка выгрузки каталога %1 в каталог %2, корень %3", ОтносительныйПутьКаталога, КаталогВыгрузки, КаталогКорень));
	
	ИмяКаталогаВыгрузки = Новый Файл(КаталогВыгрузки).Имя;
	
	Файлы = НайтиФайлы(ПутьКаталога, ПолучитьМаскуВсеФайлы());
	Для Каждого Файл из Файлы Цикл
		Если Файл.ЭтоКаталог() Тогда
			
			РазобратьКаталог(Новый Файл(Файл.ПолноеИмя), КаталогВыгрузки, КаталогКорень);

		ИначеЕсли ТипФайлаПоддерживается(Файл) Тогда
			Лог.Информация(СтрШаблон("Подготовка выгрузки файла %1 в каталог %2", Файл.Имя, ИмяКаталогаВыгрузки));

			РазобратьФайлВнутр(Файл, КаталогВыгрузки, КаталогКорень);

			Лог.Информация(СтрШаблон("Завершена выгрузка файла %1 в каталог %2", Файл.Имя, ИмяКаталогаВыгрузки));
		КонецЕсли;
	КонецЦикла;
	
	Лог.Информация(СтрШаблон("Завершена выгрузка каталога %1 в каталог %2, корень %3", ОтносительныйПутьКаталога, КаталогВыгрузки, КаталогКорень));
КонецПроцедуры

Функция РазобратьФайл(Знач Файл, Знач КаталогВыгрузки, Знач КаталогКорень = "") Экспорт
	ПутьФайла = Файл.ПолноеИмя;
	Лог.Информация(СтрШаблон("Проверка необходимости выгрузки файла %1 в каталог %2, корень %3", ПутьФайла, КаталогВыгрузки, КаталогКорень));
	
	КаталогИсходников = РазобратьФайлВнутр(Файл, КаталогВыгрузки, КаталогКорень);
	
	Лог.Информация(СтрШаблон("Завершена проверка необходимости выгрузки файла %1 в каталог %2, корень %3", ПутьФайла, КаталогВыгрузки, КаталогКорень));
	
	Возврат КаталогИсходников;
	
КонецФункции

Функция ТипФайлаПоддерживается(Файл)
	Если ПустаяСтрока(Файл.Расширение) Тогда
		Возврат Ложь;
	КонецЕсли;
	
	Поз = Найти(".epf,.erf,", Файл.Расширение+",");
	Возврат Поз > 0;
	
КонецФункции

Функция РазобратьФайлВнутр(Знач Файл, Знач КаталогВыгрузки, Знач КаталогКорень)
	
	ПутьФайла = Файл.ПолноеИмя;
	Если Не ТипФайлаПоддерживается(Файл) Тогда
		ВызватьИсключение "Тип файла """+Файл.Расширение+""" не поддерживается";
	КонецЕсли;
	
	Ожидаем.Что(Файл.Существует(), "Файл " + ПутьФайла + " должен существовать").ЭтоИстина();
	
	ОтносительныйПутьКаталогаФайла = ПолучитьОтносительныйПутьФайла(КаталогКорень, ОбъединитьПути(Файл.Путь, Файл.ИмяБезРасширения));
	Лог.Отладка("ОтносительныйПутьКаталогаФайла <"+ОтносительныйПутьКаталогаФайла+">");
	
	ПутьКаталогаИсходников = ОбъединитьПути(КаталогВыгрузки, ОтносительныйПутьКаталогаФайла);
	Лог.Отладка("ПутьКаталогаИсходников <"+ПутьКаталогаИсходников+">");
	ПапкаИсходников = Новый Файл(ПутьКаталогаИсходников);

	ОбеспечитьПустойКаталог(ПапкаИсходников);
	ЗапуститьРаспаковку(Файл, ПапкаИсходников);
	
	Возврат ПапкаИсходников.ПолноеИмя;
	
КонецФункции

Функция ПолучитьОтносительныйПутьФайла(КаталогКорень, ВнутреннийКаталог)
	Если ПустаяСтрока(КаталогКорень) Тогда	
		Возврат "";
	КонецЕсли;
	
	ФайлКорень = Новый Файл(КаталогКорень);
	ФайлВнутреннийКаталог = Новый Файл(ВнутреннийКаталог);
	Рез = СтрЗаменить(ФайлВнутреннийКаталог.ПолноеИмя, ФайлКорень.ПолноеИмя, "");
	Если Лев(Рез, 1) = "\" Тогда
		Рез = Сред(Рез, 2);
	КонецЕсли;
	Если Прав(Рез, 1) = "\" Тогда
		Рез = Лев(Рез, СтрДлина(Рез)-1);
	КонецЕсли;
	Возврат Рез;
КонецФункции

Процедура ЗапуститьРаспаковку(Знач Файл, Знач ПапкаИсходников)
	
	Лог.Отладка("Запускаем распаковку файла");
	
	Конфигуратор = Новый УправлениеКонфигуратором();
	КаталогВременнойИБ = ВременныеФайлы.СоздатьКаталог();
	Конфигуратор.КаталогСборки(КаталогВременнойИБ);
	
	ЛогКонфигуратора = Логирование.ПолучитьЛог("oscript.lib.v8runner");
	ЛогКонфигуратора.УстановитьУровень(Лог.Уровень());
	
	Параметры = Конфигуратор.ПолучитьПараметрыЗапуска();
	Параметры[0] = "ENTERPRISE";
	
	ПутьV8Reader = ОбъединитьПути(ТекущийСценарий().Каталог, "v8Reader", "V8Reader.epf");
	Лог.Отладка("Путь к V8Reader: " + ПутьV8Reader);
	Ожидаем.Что(Новый Файл(ПутьV8Reader).Существует()).ЭтоИстина();
	
	КоманднаяСтрокаV8Reader = СтрЗаменить("/C""decompile;pathtocf;%1;pathout;%2;convert-mxl2txt;ЗавершитьРаботуПосле;""","%1", Файл.ПолноеИмя);
	КоманднаяСтрокаV8Reader = СтрЗаменить(КоманднаяСтрокаV8Reader,"%2", ПапкаИсходников.ПолноеИмя);
	
	Лог.Отладка("Командная строка V8Reader: " + КоманднаяСтрокаV8Reader);

	Параметры.Добавить("/RunModeOrdinaryApplication");
	Параметры.Добавить("/Execute """ + ПутьV8Reader + """");
	Параметры.Добавить(КоманднаяСтрокаV8Reader);
	
	Конфигуратор.ВыполнитьКоманду(Параметры);
	Лог.Отладка("Вывод 1С:Предприятия - " + Конфигуратор.ВыводКоманды());
	Лог.Отладка("Очищаем каталог временной ИБ");
	
КонецПроцедуры

Процедура ОбеспечитьПустойКаталог(Знач ФайлОбъектКаталога)
	
	Если Не ФайлОбъектКаталога.Существует() Тогда
		Лог.Отладка("Создаем новый каталог " + ФайлОбъектКаталога.ПолноеИмя);
		СоздатьКаталог(ФайлОбъектКаталога.ПолноеИмя);
	ИначеЕсли ФайлОбъектКаталога.ЭтоКаталог() Тогда
		Лог.Отладка("Очищаем каталог " + ФайлОбъектКаталога.ПолноеИмя);
		УдалитьФайлы(ФайлОбъектКаталога.ПолноеИмя, ПолучитьМаскуВсеФайлы());
	Иначе
		ВызватьИсключение "Путь " + ФайлОбъектКаталога.ПолноеИмя + " не является каталогом. Выгрузка невозможна";
	КонецЕсли;
	
КонецПроцедуры


Процедура ВывестиСправку()
	Сообщить("Утилита сборки/разборки внешних файлов 1С");
	Сообщить(ПолучитьВерсию());
	Сообщить(" ");
	Сообщить("Параметры командной строки:");
	Сообщить("	--decompile inputPath outputPath");
	Сообщить("		Разбор файлов на исходники");
	
	Сообщить("	--help");
	Сообщить("		Показ этого экрана");
	Сообщить("	--git-precommit outputPath [--remove-orig-bin-files]");
	Сообщить("		Запустить чтение индекса из git и определить список файлов для разбора, разложить их и добавить исходники в индекс");
	Сообщить("		Если передан флаг --remove-orig-bin-files, обработанные файлы epf/ert будут удалены из индекса git");
	Сообщить("	--compile inputPath outputPath [--recursive]");
	Сообщить("		Собрать внешний файл/обработку.");
	Сообщить("		Если указан параметр --recursive, скрипт будет рекурсивно искать исходные коды отчетов и обработок в указанном каталоге и собирать их, повторяя структуру каталога");
КонецПроцедуры


Процедура ОбработатьИзмененияИзГит(Знач ВыходнойКаталог, Знач УдалятьФайлыИзИндексаГит) Экспорт
	
	Если ПустаяСтрока(ВыходнойКаталог) Тогда
		ВыходнойКаталог = "src";
	КонецЕсли;
	КореньРепо = ТекущийКаталог();
	Лог.Отладка("Текущий каталог " + КореньРепо);
	Лог.Отладка("Каталог выгрузки " + ВыходнойКаталог);

	ПроверитьНастройкиРепозитарияГит();
	
	ЖурналИзмененийГитСтрокой = ПолучитьЖурналИзмененийГит();
	ИменаФайлов = ПолучитьИменаИзЖурналаИзмененийГит(ЖурналИзмененийГитСтрокой);
	
	КаталогИсходников = ОбъединитьПути(КореньРепо, ВыходнойКаталог);
	СписокНовыхКаталогов = Новый Массив;
	Для Каждого Файл Из ИменаФайлов Цикл
		Лог.Отладка("Изучаю файл из журнала git " + Файл);
		Если ТипФайлаПоддерживается(Новый Файл(Файл)) Тогда
			Лог.Отладка("Получен из журнала git файл " + Файл);
			ПолныйПуть = ОбъединитьПути(КореньРепо, Файл);
			СписокНовыхКаталогов.Добавить(РазобратьФайл(Новый Файл(ПолныйПуть), КаталогИсходников, КореньРепо));
			Если УдалятьФайлыИзИндексаГит Тогда
				УдалитьФайлИзИндексаГит(ПолныйПуть);
			КонецЕсли;
		КонецЕсли;
	КонецЦикла;
	
	ДобавитьИсходникиВГит(СписокНовыхКаталогов);
	
КонецПроцедуры

Процедура УдалитьФайлИзИндексаГит(Знач ПолныйПуть)
	Лог.Отладка("Удаляю файл из индекса");
	Вывод = ПолучитьВыводПроцесса("git rm --cached """ + ПолныйПуть + """", КодВозврата);
	Лог.Отладка("Вывод git rm --cached: " + Вывод);
	Если КодВозврата <> 0 Тогда
		ВызватьИсключение "Не удалось удалить файл из журнала изменений git";
	КонецЕсли;
КонецПроцедуры

Процедура ПроверитьНастройкиРепозитарияГит() Экспорт
	Перем КодВозврата;
	
	КомандаПроверкаСостояния = "git config --local core.quotepath";
	Лог.Отладка("Выполняю команду "+КомандаПроверкаСостояния);

	Вывод = ПолучитьВыводПроцесса(КомандаПроверкаСостояния, КодВозврата);
	Вывод = СокрЛП(Вывод);
	Лог.Отладка("	Код возврата " + КодВозврата);
	Лог.Отладка("	Вывод команды <" + Вывод + ">");
	Если КодВозврата = 0 И Вывод = "false" Тогда
		Возврат;
	КонецЕсли;
	
	ВызватьИсключение "У репозитария не заданы необходимые настройки
	|Выполните команду git config --local core.quotepath false";
	
КонецПроцедуры


Функция ПолучитьЖурналИзмененийГит()
	
	Перем КодВозврата;
	
	Вывод = ВыполнитьКомандуГит("git diff-index --name-status --cached HEAD", КодВозврата, Ложь);
	Если КодВозврата <> 0 Тогда
		Вывод = ВыполнитьКомандуГит("git status --porcelain", КодВозврата, Ложь);
		
		Если КодВозврата <> 0 Тогда
			ВызватьИсключение "Не удалось собрать журнал изменений git";
		КонецЕсли;
		
	КонецЕсли;
	
	Возврат Вывод;
	
КонецФункции

Функция ВыполнитьКомандуГит(КомандаГит, КодВозврата = Неопределено, ПроверятьНулевойКодВозврата = Истина)
	
	Лог.Отладка("Запускаю "+КомандаГит);
	Вывод = ПолучитьВыводПроцесса(КомандаГит, КодВозврата);
	Лог.Отладка("	Вывод команды гит: " + Вывод);
	Если ПроверятьНулевойКодВозврата Тогда
		Ожидаем.Что(КодВозврата, "Код возврата `"+КомандаГит+"` должен быть 0, а это не так").Равно(0);
	КонецЕсли;
	Возврат Вывод;
КонецФункции

Функция ПолучитьВыводПроцесса(Знач КоманднаяСтрока, КодВозврата)
	
	// // Это для dev версии 1.0.11
	// Процесс = СоздатьПроцесс(КоманднаяСтрока, , Истина,, КодировкаТекста.UTF8);
	// Процесс.Запустить();
	// Вывод = "";
	
	// Процесс.ОжидатьЗавершения();
	
	// Вывод = Вывод + Процесс.ПотокВывода.Прочитать();
	// Вывод = Вывод + Процесс.ПотокОшибок.Прочитать();
	
	// КодВозврата = Процесс.КодВозврата;
	
	ЛогФайл = ВременныеФайлы.НовоеИмяФайла();
	СтрокаЗапуска = "cmd /C """ + КоманднаяСтрока + " > """ + ЛогФайл + """ 2>&1""";
	Лог.Отладка(СтрокаЗапуска);
	ЗапуститьПриложение(СтрокаЗапуска,, Истина, КодВозврата);
	Лог.Отладка("Код возврата: " + КодВозврата);
	ЧтениеТекста = Новый ЧтениеТекста(ЛогФайл, "utf-8");
	Вывод = ЧтениеТекста.Прочитать();
	ЧтениеТекста.Закрыть();
	
	Возврат Вывод;
	
КонецФункции

Функция ПолучитьИменаИзЖурналаИзмененийГит(Знач ЖурналИзмененийГит) Экспорт
	Лог.Отладка("ЖурналИзмененийГит:");
	МассивИмен = Новый Массив;
	// Если Найти(ЖурналИзмененийГит, Символы.ПС) > 0 Тогда
		МассивСтрокЖурнала = СтроковыеФункции.РазложитьСтрокуВМассивПодстрок(ЖурналИзмененийГит, Символы.ПС);
	// Иначе
		// ЖурналИзмененийГит = СтрЗаменить(ЖурналИзмененийГит, "A"+Символ(0), "A"+" ");
		// ЖурналИзмененийГит = СтрЗаменить(ЖурналИзмененийГит, "M"+Символ(0), "M"+" ");
		// ЖурналИзмененийГит = СтрЗаменить(ЖурналИзмененийГит, Символ(0), Символы.ПС);
		// МассивСтрокЖурнала = СтроковыеФункции.РазложитьСтрокуВМассивПодстрок(ЖурналИзмененийГит, Символы.ПС); //Символ(0));
	// КонецЕсли;
	
	Для Каждого СтрокаЖурнала Из МассивСтрокЖурнала Цикл
		Лог.Отладка("	<"+СтрокаЖурнала +">");
		СтрокаЖурнала = СокрЛ(СтрокаЖурнала);
		СимволИзменений = Лев(СтрокаЖурнала, 1);
		Если СимволИзменений = "A" или СимволИзменений = "M" Тогда
			ИмяФайла = СокрЛП(Сред(СтрокаЖурнала, 2));
			// ИмяФайла = СтрЗаменить(ИмяФайла, Символ(0), "");
			МассивИмен.Добавить(ИмяФайла);
			Лог.Отладка("		В журнале git найдено имя файла <"+ИмяФайла+">");
		КонецЕсли;
	КонецЦикла;
	Возврат МассивИмен;
КонецФункции

Процедура ДобавитьИсходникиВГит(Знач СписокНовыхКаталогов)

	Перем КодВозврата;
	
	Для Каждого Каталог Из СписокНовыхКаталогов Цикл
		
		Лог.Отладка("Запуск git add для каталога " + Каталог);
		Вывод = ПолучитьВыводПроцесса("git add --all " + ОбернутьПутьВКавычки(Каталог), КодВозврата);
		Лог.Отладка("Вывод git add: " + Вывод);
		Если КодВозврата <> 0 Тогда
			Лог.Ошибка(Вывод);
			ЗавершитьРаботу(КодВозврата);
		КонецЕсли;
		
	КонецЦикла

КонецПроцедуры

Функция Компилировать(Знач Путь, Знач КаталогВыгрузки, Знач Рекурсивно = Ложь) Экспорт

	ПутьКИсходникам = ОбъединитьПути(ТекущийКаталог(), Путь);
 
	ПапкаИсходников = Новый Файл(ПутьКИсходникам);
	
	Ожидаем.Что(ПапкаИсходников.Существует(), "Папка " + ПутьКИсходникам + " должна существовать").ЭтоИстина();
	Ожидаем.Что(ПапкаИсходников.ЭтоКаталог(), "Путь " + ПутьКИсходникам + "должен быть каталогом").ЭтоИстина();
	
	Если Рекурсивно Тогда
		СобратьКаталог(ПутьКИсходникам, КаталогВыгрузки);
	Иначе
		СобратьФайл(ПутьКИсходникам, КаталогВыгрузки);
	КонецЕсли;

КонецФункции

Процедура СобратьКаталог(Знач ПутьКИсходникам, КаталогВыгрузки)

	СписокФайловВКаталоге = НайтиФайлы(ПутьКИсходникам);

	Если НЕ Новый Файл(КаталогВыгрузки).Существует() Тогда
		СоздатьКаталог(КаталогВыгрузки);
	КонецЕсли;

	Для Каждого Файл Из СписокФайловВКаталоге Цикл
		
		Если НЕ Файл.ЭтоКаталог() Тогда
			Продолжить;
		КонецЕсли;

		Если ЭтоПутьКИсходнымКодамОбработок(Файл.ПолноеИмя) Тогда
			СобратьФайл(Файл.ПолноеИмя, КаталогВыгрузки);
		Иначе
			НовыйПутьВыгрузки = ОбъединитьПути(КаталогВыгрузки, Файл.Имя);
			СобратьКаталог(Файл.ПолноеИмя, НовыйПутьВыгрузки);
		КонецЕсли;

	КонецЦикла;

КонецПроцедуры

Функция СобратьФайл(Знач ПутьКИсходникам, Знач КаталогВыгрузки)
	
	Лог.Информация("Собираю исходники <"+ПутьКИсходникам+">");

	ПапкаИсходников = Новый Файл(ПутьКИсходникам);

	Переименования = ПолучитьСоответствиеПереименований(ПутьКИсходникам);
	
	ВременныйКаталог = ВременныеФайлы.СоздатьКаталог();
	Лог.Информация("Восстанавливаю структуру исходников в <" + ВременныйКаталог + ">");

	Для Каждого Переименование Из Переименования Цикл

		НовыйПуть = ОбъединитьПути(ВременныйКаталог, Переименование.Ключ);
		НовыйКаталог = Новый Файл(НовыйПуть);
		ПутьДоНовогоКаталога = НовыйКаталог.Путь;
		Если НЕ Новый Файл(ПутьДоНовогоКаталога).Существует() Тогда
			СоздатьКаталог(ПутьДоНовогоКаталога);
		КонецЕсли;

		СтарыйПуть = ОбъединитьПути(ПутьКИсходникам, Переименование.Значение);
		СтарыйКаталог = Новый Файл(СтарыйПуть);
		Если СтарыйКаталог.ЭтоКаталог() Тогда
			КопироватьСодержимоеКаталога(СтарыйПуть, НовыйПуть);
			Если ЭтоПутьКТолстойФорме(НовыйПуть) Тогда
				ПереместитьФайл(ОбъединитьПути(НовыйПуть, "module.bsl"), ОбъединитьПути(НовыйПуть, "module"));
			КонецЕсли;
		Иначе
			КопироватьФайл(СтарыйПуть, НовыйПуть);
		КонецЕсли;

	КонецЦикла;

	ТипФайла = ПолучитьТипФайлаПоКаталогуИсходников(ВременныйКаталог);

	ИмяПапки = ПапкаИсходников.Имя;
	ИмяФайлаОбъекта = ОбъединитьПути(ТекущийКаталог(), КаталогВыгрузки, ИмяПапки + "." + ТипФайла);
	
	СобратьФайлИзИсходников(ВременныйКаталог, ИмяФайлаОбъекта);
	Лог.Информация("Успешно собран файл "+ИмяФайлаОбъекта);

	Возврат ИмяФайлаОбъекта;

КонецФункции

Функция ЭтоПутьКИсходнымКодамОбработок(ПутьКПапке)
	
	ФайлПереименования = Новый Файл(ОбъединитьПути(ПутьКПапке, "renames.txt"));
	Возврат ФайлПереименования.Существует();

КонецФункции

Функция ЭтоПутьКТолстойФорме(ПутьКПапке)
	
	ФайлМодуля = Новый Файл(ОбъединитьПути(ПутьКПапке, "module.bsl"));
	ФайлФормы  = Новый Файл(ОбъединитьПути(ПутьКПапке, "form"));
	
	Возврат ФайлМодуля.Существует() И ФайлФормы.Существует();
	
КонецФункции

Функция ПолучитьТипФайлаПоКаталогуИсходников(Знач КаталогИсходников)

	ПутьКФайлуРут = ОбъединитьПути(КаталогИсходников, "root");
	ФайлРут = Новый Файл(ПутьКФайлуРут);
	
	Ожидаем.Что(ФайлРут.Существует(), "Файл <" + ПутьКФайлуРут +  "> должен существовать").ЭтоИстина();
	Ожидаем.Что(ФайлРут.ЭтоКаталог(), "<" + ПутьКФайлуРут +  "> должен быть файлом").ЭтоЛожь();
	
	ЧтениеТекста = Новый ЧтениеТекста(ПутьКФайлуРут);
	СодержаниеРут = ЧтениеТекста.Прочитать();
	ЧтениеТекста.Закрыть();
	МассивСтрокРут = СтрРазделить(СодержаниеРут, ",");
	Ожидаем.Что(МассивСтрокРут.Количество(), "Некорректный формат файла root").Больше(1);
	
	ПутьКФайлуКорневойКонтейнер = ОбъединитьПути(КаталогИсходников, МассивСтрокРут[1]);
	ФайлКорневойКонтейнер = Новый Файл(ПутьКФайлуКорневойКонтейнер);
		
	Ожидаем.Что(ФайлКорневойКонтейнер.Существует(), "Файл <" + ПутьКФайлуКорневойКонтейнер +  "> должен существовать").ЭтоИстина();
	Ожидаем.Что(ФайлКорневойКонтейнер.ЭтоКаталог(), "<" + ПутьКФайлуКорневойКонтейнер +  "> должен быть файлом").ЭтоЛожь();

	ЧтениеТекста = Новый ЧтениеТекста(ПутьКФайлуКорневойКонтейнер);
	СодержаниеКорневойКонтейнер = "";
	Для сч = 1 По 7 Цикл
		ПрочитаннаяСтрока = ЧтениеТекста.ПрочитатьСтроку();
		Если ПрочитаннаяСтрока = Неопределено Тогда
			Прервать;
		КонецЕсли;
		
		СодержаниеКорневойКонтейнер = СодержаниеКорневойКонтейнер + ПрочитаннаяСтрока;
	КонецЦикла;
	ЧтениеТекста.Закрыть();
	
	МассивСтрокКорневойКонтейнер = СтрРазделить(СодержаниеКорневойКонтейнер, ",");
	Ожидаем.Что(МассивСтрокКорневойКонтейнер.Количество(), "Некорректный формат файла корневого контейнера <" + ПутьКФайлуКорневойКонтейнер + ">").Больше(3);
	
	ИдентификаторТипаОбъекта = СокрЛП(МассивСтрокКорневойКонтейнер[3]);
	Если Лев(ИдентификаторТипаОбъекта, 1) = "{" Тогда
		ИдентификаторТипаОбъекта = Прав(ИдентификаторТипаОбъекта, СтрДлина(ИдентификаторТипаОбъекта) - 1);
	КонецЕсли;
	Если Прав(ИдентификаторТипаОбъекта, 1) = "}" Тогда
		ИдентификаторТипаОбъекта = Лев(ИдентификаторТипаОбъекта, СтрДлина(ИдентификаторТипаОбъекта) - 1);
	КонецЕсли;
	
	ИдентификаторТипаОбъекта = НРег(СокрЛП(ИдентификаторТипаОбъекта));

	Если ИдентификаторТипаОбъекта = "c3831ec8-d8d5-4f93-8a22-f9bfae07327f" Тогда
		ТипФайла = "epf";
	ИначеЕсли ИдентификаторТипаОбъекта = "e41aff26-25cf-4bb6-b6c1-3f478a75f374" Тогда
		ТипФайла = "erf";
	Иначе
		ВызватьИсключение("Некорректный идентификатор типа собираемого объекта <" + ИдентификаторТипаОбъекта + ">");
	КонецЕсли;

	Возврат ТипФайла;

КонецФункции

// Функция - Получает соответствие переименований файлов обработки на основе
//			 файла renames.txt
//
// Параметры:
//  ПутьКИсходникам - Строка - Путь к папке с исходными кодами обработки
// Возвращаемое значение:
//  Соответствие - Ключ: 		оригинальный путь файла после распаковки
//				   Значение:	преобразованный путь (например, при 
//								раскладывании файлов по иерархии)
//
Функция ПолучитьСоответствиеПереименований(ПутьКИсходникам)
	
	Переименования = Новый Соответствие;

	ФайлПереименования = Новый Файл(ОбъединитьПути(ПутьКИсходникам, "renames.txt"));
	
	Ожидаем.Что(ФайлПереименования.Существует(), "Файл переименования " + ФайлПереименования.ПолноеИмя + " должен существовать").ЭтоИстина();
	
	ЧтениеТекста = Новый ЧтениеТекста(ФайлПереименования.ПолноеИмя, КодировкаТекста.UTF8);
	СтрокаПереименования = ЧтениеТекста.ПрочитатьСтроку();
	Пока СтрокаПереименования <> Неопределено Цикл

		СтрокаПереименованияВрем = СтрокаПереименования;
		СтрокаПереименования = ЧтениеТекста.ПрочитатьСтроку();

		// Проверка на BOM?

		СписокСтрок = СтрРазделить(СтрокаПереименованияВрем, "-->");
		Если СписокСтрок.Количество() < 2 Тогда
			Продолжить;
		КонецЕсли;

		Лог.Отладка(СтрокаПереименованияВрем);

		ИсходныйПуть = СписокСтрок[0];
		ПреобразованныйПуть = СписокСтрок[1];
		
		Переименования.Вставить(ИсходныйПуть, ПреобразованныйПуть);

	КонецЦикла;

	Возврат Переименования;

КонецФункции

Процедура СобратьФайлИзИсходников(ПапкаИсходников, ИмяФайлаОбъекта)
	Лог.Информация("Собираю файл из исходников <"+ПапкаИсходников+"> в файл "+ИмяФайлаОбъекта);

	ПутьЗапаковщика = ОбъединитьПути(КаталогПроекта(), "tools", "v8unpack");
	Если ЭтоWindows Тогда
		ПутьЗапаковщика = ПутьЗапаковщика+".exe";
	КонецЕсли;
	Ожидаем.Что(Новый Файл(ПутьЗапаковщика).Существует(), "Не найден путь к v8unpack").ЭтоИстина();

	ВременныйФайл = ВременныеФайлы.СоздатьФайл();

	КомандаЗапуска = """%1"" -B ""%2"" ""%3""";
	КомандаЗапуска = СтрШаблон(КомандаЗапуска, ПутьЗапаковщика, ПапкаИсходников, ВременныйФайл);
	Лог.Отладка(КомандаЗапуска);

	Процесс = СоздатьПроцесс(КомандаЗапуска, , Истина, , КодировкаТекста.UTF8);
	Процесс.Запустить();
	Процесс.ОжидатьЗавершения();
	
	ВыводПроцесса = Процесс.ПотокВывода.Прочитать();
	Ожидаем.Что(Процесс.КодВозврата, "Не удалось упаковать каталог " + ПапкаИсходников + Символы.ПС + ВыводПроцесса).Равно(0);
	Лог.Отладка(ВыводПроцесса);
	
	ФайлОбъекта = Новый Файл(ИмяФайлаОбъекта);
	Лог.Отладка(СтрШаблон("Перемещение из %1 в %2", ВременныйФайл, ИмяФайлаОбъекта));
	Если ФайлОбъекта.Существует() Тогда
		Лог.Отладка(СтрШаблон("Удаляю старый файл %1 ", ИмяФайлаОбъекта));
		УдалитьФайлы(ИмяФайлаОбъекта);
	КонецЕсли;
	
	ПереместитьФайл(ВременныйФайл, ИмяФайлаОбъекта);

КонецПроцедуры

Процедура КопироватьСодержимоеКаталога(Откуда, Куда)
	
	КаталогНазначения = Новый Файл(Куда);
	Если КаталогНазначения.Существует() Тогда
		Если КаталогНазначения.ЭтоФайл() Тогда
			УдалитьФайлы(КаталогНазначения.ПолноеИмя);
			СоздатьКаталог(Куда);
		КонецЕсли;
	Иначе
		СоздатьКаталог(Куда);
	КонецЕсли;

	Файлы = НайтиФайлы(Откуда, ПолучитьМаскуВсеФайлы());
	Для Каждого Файл Из Файлы Цикл
		ПутьКопирования = ОбъединитьПути(Куда, Файл.Имя);
		Если Файл.ЭтоКаталог() Тогда
			КопироватьСодержимоеКаталога(Файл.ПолноеИмя, ПутьКопирования);
		Иначе
			КопироватьФайл(Файл.ПолноеИмя, ПутьКопирования);
		КонецЕсли;
	КонецЦикла;

КонецПроцедуры

Функция ПолучитьПутьПрограммыИзСистемныхПутейЗапускаPath(ИмяФайла)
	
	НайденныеФайлы = Новый Массив;
	Расширение = "";

	Если ЭтоWindows Тогда
		Расширение = ".exe";
	КонецЕсли;

	СистемнаяИнформация = Новый СистемнаяИнформация;
	ПапкаПоиска = СистемнаяИнформация.ПолучитьПеременнуюСреды("PATH");
	РазделительПапок = ";"; 
	СписокПапок = СтрРазделить(ПапкаПоиска, РазделительПапок);
	Для сч = 0 По СписокПапок.ВГраница() Цикл

		ПроверяемаяПапка = СписокПапок[сч];
		
		// На Windows папка может быть обернута в кавычки, сбросим их
		Если ЭтоWindows 
				И СтрДлина(ПроверяемаяПапка) >= 2 
				И Лев(ПроверяемаяПапка, 1) = """"
				И Прав(ПроверяемаяПапка, 1) = """" Тогда
			ПроверяемаяПапка = Сред(ПроверяемаяПапка, 2, СтрДлина(ПроверяемаяПапка) - 2);
		КонецЕсли;

		ПутьПоиска = ОбъединитьПути(ПроверяемаяПапка, ИмяФайла + Расширение);
		ФайлПоиска = Новый Файл(ПутьПоиска);
		Если ФайлПоиска.Существует() И НайденныеФайлы.Найти(ПутьПоиска) = Неопределено Тогда
			НайденныеФайлы.Добавить(ПутьПоиска);
		КонецЕсли;

	КонецЦикла;

	НайденныйФайл = "";
	Если НайденныеФайлы.Количество() > 0 Тогда
		НайденныйФайл = НайденныеФайлы[0];
	КонецЕсли;

	Возврат НайденныйФайл;

КонецФункции

Функция ОбернутьПутьВКавычки(Знач Путь)

	Результат = Путь;
	Если Прав(Результат, 1) = "\" Тогда
		Результат = Лев(Результат, СтрДлина(Результат) - 1);
	КонецЕсли;

	Результат = """" + Результат + """";

	Возврат Результат;

КонецФункции

Функция КаталогПроекта()
	ФайлИсточника = Новый Файл(ТекущийСценарий().Источник);
	Возврат ФайлИсточника.Путь;
КонецФункции

Функция ИмяСкрипта()
	ФайлИсточника = Новый Файл(ТекущийСценарий().Источник);
	Возврат ФайлИсточника.ИмяБезРасширения;
КонецФункции

Инициализация();

Если ЗапускВКоманднойСтроке() Тогда
	ЗавершитьРаботу(КодВозврата);
КонецЕсли;
