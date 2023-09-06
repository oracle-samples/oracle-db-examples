drop table testgist;
create table testgist (pk number primary key, text clob);

insert into testgist values (1, 
'Here is a complete load of guff I just typed in to'||chr(10)||
'represent some text in a document. This is the first'||chr(10)||
'paragraph with some line breaks in it.'||chr(10)||
''||chr(10)||
'This is the second paragraph which is separated from'||chr(10)||
'the first by having two linefeed characters in it.'||chr(10)||
''||chr(10)||
'Of course being that this is in Windoze it might just'||chr(10)||
'have carriage-return, linefeed at the end of each line.'||chr(10)||
''||chr(10)||
'And they all lived happily ever after, until George Bush'||chr(10)||
'bombed them back to the stone age.'||chr(10)||
'');

insert into testgist values (2, 
'ADVICE FOR AMERICANS TRAVELLING TO BRITAIN '||chr(10)||
' '||chr(10)||
'MONEY '||chr(10)||chr(10)||
'The Brits have peculiar words for many things. Money is referred to as '||chr(10)||
'"goolies" in slang, so you should for instance say "I''d love to come to the '||chr(10)||
'pub but I haven''t got any goolies. " "Quid" is the modern word for what was '||chr(10)||
'once called a "shilling" - the equivalent of seventeen cents American. '||chr(10)||
' '||chr(10)||
'MAKING FRIENDS '||chr(10)||chr(10)||
'If you are fond of someone, you should tell him he is a "great tosser" - he '||chr(10)||
'will be touched. The English are a notoriously tactile, demonstrative '||chr(10)||
'people, and if you want to fit in you should hold hands with your '||chr(10)||
'acquaintances and tossers when you walk down the street. '||chr(10)||
' '||chr(10)||
'CUSTOMS '||chr(10)||chr(10)||
'Since their Tory government wholeheartedly embraced full union with Europe, '||chr(10)||
'the Brits have been attempting to adopt certain continental customs, such as '||chr(10)||
'the large midday meal followed by a two or three hour siesta, which they '||chr(10)||
'call a "wank". As this is still a fairly new practice in Britain, it is not '||chr(10)||
'uncommon for people to oversleep (alarm clocks, alas, do not work there due '||chr(10)||
'to the magnetic pull from Greenwich). If you are late for supper, simply '||chr(10)||
'apologise and explain that you were having a wank - everyone will understand '||chr(10)||
'and forgive you. '||chr(10)||
' '||chr(10)||
'RELAXING '||chr(10)||
'One of the most delightful ways to spend an afternoon in Oxford or Cambridge '||chr(10)||
'is gliding gently down the river in one of their flat-bottomed boats, which '||chr(10)||
'you propel using a long pole. This is known as "cottaging". '||chr(10)||
' '||chr(10)||
'Many of the boats (called "yer-i-nals") are privately owned by the colleges, '||chr(10)||
'but there are some places that rent them to the public by the hour. Just '||chr(10)||
'tell a professor or policeman that you are interested in doing some '||chr(10)||
'cottaging and would like to know where the public yerinals are. The poles '||chr(10)||
'must be treated with vegetable oil to protect them from the water, so it''s a '||chr(10)||
'good idea to buy a can of Mazola and have it on you when you ask directions '||chr(10)||
'to the yerinals. That way people will know you are an experienced cottager. '||chr(10)||
' '||chr(10)||
'FOOD AND WINE '||chr(10)||
'British cuisine enjoys a well deserved reputation as the most sublime '||chr(10)||
'gastronomic pleasure available to man. Thanks to today''s robust dollar, the '||chr(10)||
'American traveler can easily afford to dine out several times a week rest '||chr(10)||
'assured that a British meal is worth interrupting your afternoon wank for. '||chr(10)||
' '||chr(10)||
'Few foreigners are aware that there are several grades of meat in the UK. '||chr(10)||
'The best cuts of meat, like the best bottles of gin, bear Her Majesty''s '||chr(10)||
'seal, called the British Stamp of Excellence (BSE). When you go to a fine '||chr(10)||
'restaurant, tell your waiter you want BSE beef and won''t settle for anything '||chr(10)||
'less. If he balks at your request, custom dictates that you jerk your head '||chr(10)||
'imperiously back and forth while rolling your eyes to show him who is boss. '||chr(10)||
'Once the waiter realizes you are a person of discriminating taste, he may '||chr(10)||
'offer to let you peruse the restaurant''s list of exquisite British wines. If '||chr(10)||
'he does not, you should order one anyway. The best wine grapes grow on the '||chr(10)||
'steep, chalky hillsides of Yorkshire and East Anglia. Try an Ely ''84 or '||chr(10)||
'Ripon ''88 for a rare treat indeed. When the bill for your meal comes it will '||chr(10)||
'show a suggested amount. Pay whatever you think is fair, unless you plan to '||chr(10)||
'dine there again, in which case you should simply walk out; the restaurant '||chr(10)||
'host will understand that he should run a tab for you. '||chr(10)||
' '||chr(10)||
'');

commit;

create index med_idx on testgist(text) indextype is ctxsys.context;
