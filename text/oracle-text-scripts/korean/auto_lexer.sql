set echo on

drop table multitext;
create table multitext (language_ident varchar2(20), text varchar2(4000));

insert into multitext values ('en', '
Prince Harry has lost a legal challenge over his bid to be allowed to make private payments for police protection.
His lawyers wanted a judicial review of the rejection of his offer to pay for protection in the UK, after his security arrangements changed when the prince stopped being a "working royal".
But a judge has ruled not to give the go ahead for such a hearing.
Home Office lawyers had opposed the idea of allowing wealthy people to "buy" security from the police.
This ruling followed a one-day court hearing in London last week.
Since then the Duke and Duchess of Sussex have been involved in what their spokesperson described as a "near catastrophic car chase" involving paparazzi in New York.
But at the High Court last week, lawyers for Prince Harry had challenged the decision to reject his private funding for police protection for himself and his family when visiting the UK.
This added at the end 123 abc123 def-123');

insert into multitext values ('ko', '
해리 왕자는 경찰 보호를 위해 개인 지불을 허용하려는 그의 입찰에 대한 법적 도전에서 패했습니다.
그의 변호사는 왕자가 "일하는 왕족"이 되는 것을 중단했을 때 그의 보안 조치가 변경된 후 영국에서 보호 비용을 지불하겠다는 그의 제안을 거부한 것에 대해 사법적 검토를 원했습니다.
그러나 판사는 그러한 청문회를 진행하지 않기로 판결했습니다.
내무부 변호사들은 부유한 사람들이 경찰로부터 보안을 "구매"하도록 허용하는 아이디어에 반대했습니다.
이 판결은 지난 주 런던에서 하루 동안 진행된 법원 심리에 이은 것입니다.
그 이후로 서섹스 공작과 공작부인은 그들의 대변인이 뉴욕에서 파파라치가 연루된 "거의 재앙에 가까운 자동차 추격전"이라고 묘사한 것에 연루되었습니다.
그러나 지난 주 고등법원에서 해리 왕자의 변호인단은 영국을 방문할 때 자신과 가족을 위한 경찰 보호를 위한 개인 자금 지원을 거부한 결정에 이의를 제기했습니다.');

exec ctx_ddl.drop_preference('auto_lex')

begin
    ctx_ddl.create_preference('auto_lex','AUTO_LEXER');
end;
/

create index multiindex on multitext (text) 
indextype is ctxsys.context
parameters ('lexer auto_lex');

select * from multitext where contains (text, '123') > 0;

select * from multitext where contains (text, '왕자의') > 0;
