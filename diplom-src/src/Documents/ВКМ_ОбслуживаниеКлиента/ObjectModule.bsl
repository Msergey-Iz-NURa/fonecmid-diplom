
Процедура ОбработкаПроведения(Отказ, Режим)

	Запрос = Новый Запрос;
	Запрос.Текст = 
		"ВЫБРАТЬ
		|	ВКМ_ОбслуживаниеКлиентаВыполненныеРаботы.Ссылка.Клиент КАК Клиент,
		|	ВКМ_ОбслуживаниеКлиентаВыполненныеРаботы.Ссылка.Договор КАК Договор,
		|	ВКМ_ОбслуживаниеКлиентаВыполненныеРаботы.Ссылка.Договор.ВидДоговора КАК ВидДоговора,
		|	ВКМ_ОбслуживаниеКлиентаВыполненныеРаботы.ЧасыКОплатеКлиенту КАК ЧасыКОплатеКлиенту,
		|	ВКМ_ОбслуживаниеКлиентаВыполненныеРаботы.Ссылка.Договор.ВКМ_СтоимостьЧасаРаботы КАК СтоимостьЧасаРаботы,
		|	ВКМ_ОбслуживаниеКлиентаВыполненныеРаботы.Ссылка.Договор.ВКМ_Дата КАК ДатаДоговора,
		|	ВКМ_ОбслуживаниеКлиентаВыполненныеРаботы.Ссылка.Договор.ВКМ_ПериодДействия КАК ПериодДействияДоговора,
		|	ВКМ_ОбслуживаниеКлиентаВыполненныеРаботы.ОписаниеРабот КАК ОписаниеРабот
		|ИЗ
		|	Документ.ВКМ_ОбслуживаниеКлиента.ВыполненныеРаботы КАК ВКМ_ОбслуживаниеКлиентаВыполненныеРаботы
		|ГДЕ
		|	ВКМ_ОбслуживаниеКлиентаВыполненныеРаботы.Ссылка = &Ссылка";
	
	Запрос.УстановитьПараметр("Ссылка", Ссылка);
	Выборка = Запрос.Выполнить().Выбрать();
	
	Движения.ВКМ_ВыполненныеКлиентуРаботы.Записывать = Истина;
	Пока Выборка.Следующий() Цикл
		Если НЕ Выборка.ВидДоговора = Перечисления.ВидыДоговоровКонтрагентов.ВКМ_АбонентскоеОбслуживание Тогда
			Отказ = Истина;
			Сообщить("Выбран не правильный вид договора.");
			Прервать;
		КонецЕсли;
		Если Дата < Выборка.ДатаДоговора ИЛИ Дата > Выборка.ПериодДействияДоговора Тогда
			Отказ = Истина;
			Сообщить("Документ не входит во временные рамки договора.");
			Прервать;
		КонецЕсли;
		
		Движение = Движения.ВКМ_ВыполненныеКлиентуРаботы.Добавить();
		Движение.ВидДвижения = ВидДвиженияНакопления.Приход;
		Движение.Период = Дата;
		Движение.Клиент = Выборка.Клиент;
		Движение.Договор = Выборка.Договор;
		Движение.ОписаниеРабот = Выборка.ОписаниеРабот;
		Движение.Сумма = Выборка.ЧасыКОплатеКлиенту * Выборка.СтоимостьЧасаРаботы;
		Движение.КоличествоЧасов = Выборка.ЧасыКОплатеКлиенту;
	КонецЦикла;
КонецПроцедуры

Процедура ПриЗаписи(Отказ)

	Если ЭтоНовый() Тогда
		НоваяЗапись = Справочники.ВКМ_УведомленияТелеграм_боту.СоздатьЭлемент();
		НоваяЗапись.ТекстСообщения = СтрШаблон("<b>Новая заявка № %6 от %7 для %8!</b> Клиент: %1, Проблема: %2, Время проведения работ: %3 с %4 по %5.",
			Клиент.Наименование, ОписаниеПроблемы, Формат(ДатаПроведенияРабот, "ДФ=dd.MM.yy"), 
			Формат(ВремяНачалаРабот, "ДФ=HH:mm"), Формат(ВремяОкончанияРабот, "ДФ=HH:mm"), Номер, Дата, Специалист);
		НоваяЗапись.Записать();
	КонецЕсли;	
		
КонецПроцедуры          

Процедура ПередЗаписью(Отказ, РежимЗаписи, РежимПроведения)

	ЗаявкаИзменена = Ложь;
	Если ОписаниеПроблемы <> Ссылка.ОписаниеПроблемы Тогда
	   ЗаявкаИзменена = Истина;  
	   ИзмениласьПроблема = СтрШаблон("Изменилась проблема: %1.", ОписаниеПроблемы);
	КонецЕсли;
	
	Если Специалист <> Ссылка.Специалист Тогда
	   ЗаявкаИзменена = Истина;  
	   ИзменилсяСпециалист = СтрШаблон("Изменился специалист: %1 на %2.", Ссылка.Специалист, Специалист);
	КонецЕсли;
		
	Если ДатаПроведенияРабот <> Ссылка.ДатаПроведенияРабот ИЛИ ВремяНачалаРабот <> Ссылка.ВремяНачалаРабот ИЛИ ВремяОкончанияРабот <> Ссылка.ВремяОкончанияРабот Тогда
	   ЗаявкаИзменена = Истина;  
	   ИзменилосьВремя = СтрШаблон("Изменилось время проведения работ на: %1 с %2 по %3.", Формат(ДатаПроведенияРабот, "ДФ=dd.MM.yy"), 
			Формат(ВремяНачалаРабот, "ДФ=HH:mm"), Формат(ВремяОкончанияРабот, "ДФ=HH:mm"));
	КонецЕсли;
	
	Если ЗначениеЗаполнено(Ссылка) И ЗаявкаИзменена Тогда
		НоваяЗапись = Справочники.ВКМ_УведомленияТелеграм_боту.СоздатьЭлемент();
		НоваяЗапись.ТекстСообщения = СтрШаблон("<b>Заявка № %1 от %2 изменена!</b> %3 %4 %5 %6", Номер, Дата, Символы.ВК,  ИзмениласьПроблема,  ИзменилсяСпециалист, ИзменилосьВремя);
		НоваяЗапись.Записать();
	КонецЕсли;
	
КонецПроцедуры



