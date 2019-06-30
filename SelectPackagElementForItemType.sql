CREATE PROCEDURE SelectPackageElementForItemType(@ID char(32)) AS
begin
print @id
declare  @res Table
(
 [Group] nvarchar(64) collate database_default,
 name nvarchar(64) collate database_default,
 element_id char(32) collate database_default,
 comments nvarchar(128)
)

-- 1) RelationshipType
insert into @res
select  'RelationshipType', rt.name, rt.ID, 'source_id in package'
 from RELATIONSHIPTYPE rt
 where rt.SOURCE_ID= @id
 and rt.ID not in (select element_id from @res)
 
-- 2) Form
insert into @res
 select 'Form', f.name, f.id, 'View source in package'
 from FORM f
 inner join [VIEW] v on v.related_id=f.ID
 where v.SOURCE_ID =@id
 and f.ID not in (select element_id from @res)
 
-- 3) Life Cycle
insert into @res
 select 'Life Cycle Map', l.name, l.id, 'LC source in package'
 from LIFE_CYCLE_MAP l
 inner join [ITEMTYPE_LIFE_CYCLE] ilc on ilc.related_id=l.ID
 where ilc.SOURCE_ID =@id
 and l.ID not in (select element_id from @res) 

-- 4) Identity, TOC Access 
insert into @res
 select distinct 'Identity', i.name, i.id, 'TOC source in package'
 from TOC_ACCESS t
 inner join [IDENTITY] i on t.related_id=i.ID
 where t.SOURCE_ID =@id
 and not i.ID  in (select element_id from @res)
 and not i.NAME  in ('World','Administrators', 'Super User', 'Innovator Admin','Creator', 'Manager', 'Owner')

-- 5) Identity, Can Add
insert into @res
 select distinct 'Identity', i.name, i.id, 'CanAdd source in package'
 from TOC_ACCESS t
 inner join [IDENTITY] i on t.related_id=i.ID
 where t.SOURCE_ID =@id
 and not i.ID  in (select element_id from @res) 
 and not i.NAME  in ('World','Administrators', 'Super User', 'Innovator Admin','Creator', 'Manager', 'Owner')

-- 6) Workflow Map
insert into @res
 select 'Workflow Map', wm.name, wm.config_id, 'Workflow source in package'
 from ALLOWED_WORKFLOW aw
 inner join [workflow_map] wm on aw.related_id=wm.ID
 where aw.SOURCE_ID =@id
 and wm.ID not in (select element_id from @res) 

-- 7) Action
insert into @res
 select 'Action', a.name, a.id, 'Action source in package'
 from item_action ia
 inner join [action] a on ia.related_id=a.ID
 where ia.SOURCE_ID =@id
 and a.ID not in (select element_id from @res) 

-- 8) Report
insert into @res
 select 'Report', r.name, r.id, 'Report sources in package'
 from item_report ir
 inner join [report] r on ir.related_id=r.ID
 where ir.SOURCE_ID =@id
 and r.ID not in (select element_id from @res) 

-- 9) PolySource
insert into @res
 select 'ItemType', i.name, i.id, 'Morphae source in package'
 from MORPHAE m
 inner join [ItemType] i on m.related_id=i.ID
 where m.SOURCE_ID =@id
 and not i.ID  in (select element_id from @res)
 
 -- 10) List
insert into @res
 select 'List', l.name, l.id, 'List source in package'
 from property p
 inner join [list] l on p.data_source=l.ID
 where p.SOURCE_ID =@id

 and l.ID not in (select element_id from @res)

-- 11) Sequence
insert into @res
 select 'Sequence', s.name, s.id, 'Sequence source in package'
 from property p
 inner join [sequence] s on p.data_source=s.ID
 where p.SOURCE_ID =@id
 and s.ID not in (select element_id from @res)

-- 11) Property of type Item
insert into @res
 select distinct 'ItemType', i.name, i.id, 'Property source in package'
 from property p
 inner join [itemtype] i on p.data_source=i.ID
 where p.SOURCE_ID =@id
 and not i.ID  in (select element_id from @res)
 and not i.NAME in ('ItemType','Life Cycle State','Permission','Revision','Team','User','History Template','Help','Identity')
 and not p.name in ('id','config_id')

-- 12) Permission
insert into @res
 select 'Permission', p.name, p.id, 'Permission source in package'
 from ALLOWED_PERMISSION ap
 inner join [Permission] p on ap.related_id=p.ID
 where ap.SOURCE_ID =@id
 and p.ID not in (select element_id from @res)

-- 13) Grid
insert into @res
select 'RelationshipType', rt.name, rt.ID, 'Grid source in package'
 from RELATIONSHIPTYPE rt
 inner join RELATIONSHIP_VIEW rv on rv.SOURCE_ID =rt.id
 inner join GRID g on rv.GRID =g.id
 where rt.SOURCE_ID= @id
 and g.ID not in (select element_id from @res)

-- 14) State Permissions
insert into @res
 select 'Permission', p.name, p.id, 'State Permission source in package'
 from LIFE_CYCLE_STATE ls
 inner join LIFE_CYCLE_MAP lm on ls.SOURCE_ID = lm.id
 inner join [ITEMTYPE_LIFE_CYCLE] ilc on ilc.related_id=lm.ID
 inner join [Permission] p on ls.STATE_PERMISSION_ID=p.ID
 where ilc.SOURCE_ID =@id
 and p.ID not in (select element_id from @res)

-- 15) State EmailMessage
insert into @res
 select distinct 'Email Message', e.name, e.id, 'LC State EmailMessage source in package'
 from LIFE_CYCLE_STATE ls
 inner join LIFE_CYCLE_MAP lm on ls.SOURCE_ID = lm.id
 inner join [ITEMTYPE_LIFE_CYCLE] ilc on ilc.related_id=lm.ID
 inner join STATE_EMAIL se on se.SOURCE_ID= ls.id
 inner join EMAIL_MESSAGE e on se.related_ID=e.ID
 where ilc.SOURCE_ID =@id
 and e.ID not in (select element_id from @res)
 
 -- 16) Transition EmailMessage
insert into @res
 select distinct 'Email Message', e.name, e.id, 'LC Transition EmailMessage source in package'
 from LIFE_CYCLE_TRANSITION lt
 inner join LIFE_CYCLE_MAP lm on lt.SOURCE_ID = lm.id
 inner join [ITEMTYPE_LIFE_CYCLE] ilc on ilc.related_id=lm.ID
 inner join transition_EMAIL te on te.SOURCE_ID= lt.id
 inner join EMAIL_MESSAGE e on te.SOURCE_ID=e.ID
 where ilc.SOURCE_ID =@id
 and e.ID not in (select element_id from @res)
 
-- 17) Identity, State Notification
insert into @res
 select distinct 'Identity', i.name, i.id, 'LC State Notification source in package'
 from LIFE_CYCLE_STATE ls
 inner join LIFE_CYCLE_MAP lm on ls.SOURCE_ID = lm.id
 inner join [ITEMTYPE_LIFE_CYCLE] ilc on ilc.related_id=lm.ID
 inner join STATE_EMAIL se on se.SOURCE_ID= ls.id
 inner join STATE_NOTIFICATION sn on sn.source_ID=se.ID
 inner join [IDENTITY] i on sn.RELATED_ID=i.id
 where ilc.SOURCE_ID =@id
 and not i.ID  in (select element_id from @res) 
 and not i.NAME  in ('World','Administrators', 'Super User', 'Innovator Admin','Creator', 'Manager', 'Owner')

-- 18) Identity, State Distribution
insert into @res
 select distinct 'Identity', i.name, i.id, 'LC State Distribution source in package'
 from LIFE_CYCLE_STATE ls
 inner join LIFE_CYCLE_MAP lm on ls.SOURCE_ID = lm.id
 inner join [ITEMTYPE_LIFE_CYCLE] ilc on ilc.related_id=lm.ID
 inner join STATE_DISTRIBUTION sd on sd.SOURCE_ID= ls.id
 inner join [IDENTITY] i on sd.RELATED_ID = i.id 
 where ilc.SOURCE_ID =@id
 and not i.ID  in (select element_id from @res)
 and not i.NAME  in ('World','Administrators', 'Super User', 'Innovator Admin','Creator', 'Manager', 'Owner')

-- 19) Identity, Transition Distribution
insert into @res
 select distinct 'Identity', i.name, i.id, 'LC Transition Distribution source in package'
 from LIFE_CYCLE_TRANSITION lt
 inner join LIFE_CYCLE_MAP lm on lt.SOURCE_ID = lm.id
 inner join [ITEMTYPE_LIFE_CYCLE] ilc on ilc.related_id=lm.ID
 inner join transition_EMAIL te on te.SOURCE_ID= lt.id
 inner join TRANSITION_DISTRIBUTION td on td.SOURCE_ID=te.ID
 inner join [IDENTITY] i on td.RELATED_ID = i.id 
 where ilc.SOURCE_ID =@id
 and not i.ID  in (select element_id from @res)
 and not i.NAME  in ('World','Administrators', 'Super User', 'Innovator Admin','Creator', 'Manager', 'Owner')

 -- 20) Identity, Access
 insert into @res
  select distinct 'Identity', i.name, i.id, 'Permission Access source in package'
  from ACCESS a
  inner join [IDENTITY] i on i.id = a.related_id
  where a.SOURCE_ID in (select element_id from @res where [Group]='Permission')
  and not i.ID  in (select element_id from @res)
  and not i.NAME  in ('World','Administrators', 'Super User', 'Innovator Admin','Creator', 'Manager', 'Owner')
  
 -- 21) List
insert into @res
 select 'Team', t.name, t.id, 'Team source in package'
 from property p
 inner join [team] t on p.team_id=t.ID
 where p.SOURCE_ID =@id
 
 -- 22) Identity, team
insert into @res
 select distinct 'Identity', i.name, i.id, 'Team Identity source in package'
 from TEAM_IDENTITY ti
 inner join [IDENTITY] i on i.id = ti.related_id
 where ti.SOURCE_ID in (select element_id from @res where [Group]='Team')
 and not i.ID  in (select element_id from @res)
 and not i.NAME  in ('World','Administrators', 'Super User', 'Innovator Admin','Creator', 'Manager', 'Owner')
	
-- 23) Identity, Activity Assignment
insert into @res
 select distinct 'Identity', i.name, i.id, 'WF Activity Assignment source in package'
 from WORKFLOW_MAP_ACTIVITY wma
 inner join ACTIVITY_TEMPLATE a on a.id=wma.RELATED_ID
 inner join WORKFLOW_MAP wm on wm.ID=wma.SOURCE_ID
 inner join ACTIVITY_TEMPLATE_ASSIGNMENT aa on aa.SOURCE_ID=a.ID
 inner join [IDENTITY] i on aa.RELATED_ID= i.ID
 where wma.SOURCE_ID in (select element_id from @res where [Group]='Workflow Map')
 and not i.ID  in (select element_id from @res)
 and not i.NAME  in ('World','Administrators', 'Super User', 'Innovator Admin', 'Creator', 'Manager', 'Owner' )

-- 23) Workflow Notification
insert into @res
 select distinct 'Email Message', e.name, e.id, 'WF EmailMessage source in package'
 from WORKFLOW_MAP_ACTIVITY wma
 inner join ACTIVITY_TEMPLATE a on a.id=wma.RELATED_ID
 inner join WORKFLOW_MAP wm on wm.ID=wma.SOURCE_ID
 inner join ACTIVITY_TEMPLATE_EMAIL ate on ate.SOURCE_ID=a.ID
 inner join EMAIL_MESSAGE e on ate.RELATED_ID= e.ID
 where wma.SOURCE_ID in (select element_id from @res where [Group]='Workflow Map')
 and e.ID not in (select element_id from @res)

 -- 24) Identity, Members
insert into @res
 select distinct 'Identity', i.name, i.id, 'Member source in package'
 from MEMBER m
 inner join [IDENTITY] i on i.id = m.related_id
 where m.SOURCE_ID in (select element_id from @res where [Group]='Identity')
 and not i.ID  in (select element_id from @res)
 and not i.NAME  in ('World','Administrators', 'Super User', 'Innovator Admin','Creator', 'Manager', 'Owner')
 and i.IS_ALIAS !='1'

-- 24A) Grid
insert into @res
 select distinct 'Grid', g.name, g.id, 'RelationshipView source in package'
 from GRID g
 inner join RELATIONSHIP_VIEW rv on rv.RELATED_ID= g.ID
 where rv.SOURCE_ID in (select element_id from @res where [Group]='RelationshipType')
 and NOT g.ID in (select element_id from @res)
-- 24b) Relationship Form
insert into @res
 select distinct 'Form', f.name, f.id, 'RelationshipView source in package'
 from FORM f
 inner join RELATIONSHIP_VIEW rv on rv.RELATED_ID= f.ID
 where rv.SOURCE_ID in (select element_id from @res where [Group]='RelationshipType')
 and NOT f.ID in (select element_id from @res)
-- 25) Method
 
declare @t1 table(method_id char(32), [Called By] varchar(64), Method varchar(64), Notes varchar(64), method_type varchar(64))

insert into @t1
-- 25.1) Server Event
SELECT    METHOD.CONFIG_ID, 'Server Event' AS [Called By], METHOD.NAME AS Method, SERVER_EVENT.SERVER_EVENT AS Notes, 
                      METHOD.METHOD_TYPE
FROM         ITEMTYPE INNER JOIN
                      SERVER_EVENT ON ITEMTYPE.ID = SERVER_EVENT.SOURCE_ID INNER JOIN
                      METHOD ON SERVER_EVENT.RELATED_ID = METHOD.ID
WHERE     (ITEMTYPE.id = @ID)
union
-- 25.2) Report
SELECT    METHOD.CONFIG_ID,  'Report' AS [Called By], METHOD.NAME as Method, REPORT.TYPE + ' Report '+ REPORT.Name AS Notes,  METHOD.METHOD_TYPE
FROM         ITEMTYPE INNER JOIN
                      ITEM_REPORT ON ITEMTYPE.ID = ITEM_REPORT.SOURCE_ID INNER JOIN
                      REPORT ON ITEM_REPORT.RELATED_ID = REPORT.ID INNER JOIN
                      METHOD ON REPORT.METHOD = METHOD.ID
WHERE     (ITEMTYPE.id = @id)
union
-- 25.3) Action
SELECT     METHOD.CONFIG_ID, 'Action' AS [Called By],  METHOD.NAME,ACTION.TYPE+ ' Action '+ Action.Name as notes, METHOD.METHOD_TYPE
FROM         ITEMTYPE INNER JOIN
                      ITEM_ACTION ON ITEMTYPE.ID = ITEM_ACTION.SOURCE_ID INNER JOIN
                      ACTION ON ITEM_ACTION.RELATED_ID = ACTION.ID INNER JOIN
                      METHOD ON ACTION.METHOD = METHOD.ID
WHERE     (ITEMTYPE.id = @id)
union
-- 25.4) ItemType Client Event
SELECT     METHOD.CONFIG_ID, 'Client Event' AS [Called By], METHOD.NAME AS Method, CLIENT_EVENT.CLIENT_EVENT AS Notes, 
                      METHOD.METHOD_TYPE
FROM         ITEMTYPE INNER JOIN
                      CLIENT_EVENT ON ITEMTYPE.ID = CLIENT_EVENT.SOURCE_ID INNER JOIN
                      METHOD ON CLIENT_EVENT.RELATED_ID = METHOD.ID
WHERE     (ITEMTYPE.id = @id)
union
-- 25.5) Field Event
SELECT     METHOD.CONFIG_ID, 'Field Event' AS [Called By], METHOD.NAME, FIELD.NAME + ', ' + FIELD_EVENT.FIELD_EVENT AS Notes, 
                      METHOD.METHOD_TYPE
FROM         ITEMTYPE INNER JOIN
                      [VIEW] ON ITEMTYPE.ID = [VIEW].SOURCE_ID INNER JOIN
                      FORM ON [VIEW].RELATED_ID = FORM.ID INNER JOIN
                      BODY ON FORM.ID = BODY.SOURCE_ID INNER JOIN
                      FIELD ON BODY.ID = FIELD.SOURCE_ID INNER JOIN
                      FIELD_EVENT ON FIELD.ID = FIELD_EVENT.SOURCE_ID INNER JOIN
                      METHOD ON FIELD_EVENT.RELATED_ID = METHOD.ID
WHERE     (ITEMTYPE.id = @id)
union
-- 25.6) Property Grid Event
SELECT     METHOD.CONFIG_ID, 'Grid Event' AS [Called By], ITEMTYPE.NAME, PROPERTY.NAME + ', ' + GRID_EVENT.GRID_EVENT AS Notes, 
                      METHOD.METHOD_TYPE
FROM         ITEMTYPE INNER JOIN
                      PROPERTY ON ITEMTYPE.ID = PROPERTY.SOURCE_ID INNER JOIN
                      GRID_EVENT ON PROPERTY.ID = GRID_EVENT.SOURCE_ID INNER JOIN
                      METHOD ON GRID_EVENT.RELATED_ID = METHOD.ID

WHERE     (ITEMTYPE.id = @id)
union
-- 25.7) Form Event
SELECT     METHOD.CONFIG_ID, 'Form Event' AS [Called By], METHOD.NAME AS Method, FORM_EVENT.FORM_EVENT AS Notes, 
                      METHOD.METHOD_TYPE
FROM         ITEMTYPE INNER JOIN
                      [VIEW] ON ITEMTYPE.ID = [VIEW].SOURCE_ID INNER JOIN
                      FORM ON [VIEW].RELATED_ID = FORM.ID INNER JOIN
                      FORM_EVENT ON FORM.ID = FORM_EVENT.SOURCE_ID INNER JOIN
                      METHOD ON FORM_EVENT.RELATED_ID = METHOD.ID
WHERE     (ITEMTYPE.id = @id)
union
-- 25.8) Relationship Grid Event
select m.CONFIG_ID, 'Relationship Grid Event' as [Called By], m.name as method, rge.GRID_EVENT as Notes, m.METHOD_TYPE
 from METHOD m
 inner join RELATIONSHIP_GRID_EVENT rge on rge.RELATED_ID=m.ID
 inner join RELATIONSHIPTYPE r on r.ID =rge.SOURCE_ID
where r.SOURCE_ID = @ID
union
-- 25.9) Pre Transition Event
select m.CONFIG_ID, 'Pre Transition Event' as [Called By], m.name as method, '' as Notes, m.METHOD_TYPE
 from METHOD m
 inner join LIFE_CYCLE_TRANSITION lct on lct.pre_action=m.ID
 inner join LIFE_CYCLE_MAP lc on lc.ID = lct.SOURCE_ID
 where lc.ID in (select element_id from @res where [group]='Life Cycle Map')
union
-- 25.9) Post Transition Event
select m.CONFIG_ID, 'Post Transition Event' as [Called By], m.name as method,'' as Notes, m.METHOD_TYPE
 from METHOD m
 inner join LIFE_CYCLE_TRANSITION lct on lct.post_action=m.ID
 inner join LIFE_CYCLE_MAP lc on lc.ID = lct.SOURCE_ID
 where lc.ID in (select element_id from @res where [group]='Life Cycle Map')
 union
-- 25.10) Activity Server Event
select m.CONFIG_ID, 'Activity Server Event' as [Called By], m.name as method, atm.EVENT as Notes, m.METHOD_TYPE
 from METHOD m
 inner join ACTIVITY_TEMPLATE_METHOD atm on atm.related_id=m.ID
 inner join ACTIVITY_TEMPLATE at on at.ID = atm.SOURCE_ID
 inner join WORKFLOW_MAP_ACTIVITY wma on wma.RELATED_ID= at.id
 where wma.source_id in (select id from workflow_map where is_current='1' and config_id in (select element_id from @res where [Group]='Workflow Map'))
union
-- 25.11) Path Pre Event
select m.CONFIG_ID, 'Path Pre Event' as [Called By], m.name as method, '' as notes, m.METHOD_TYPE
 from METHOD m
 inner join WORKFLOW_MAP_PATH_PRE wmpp on wmpp.RELATED_ID= m.id
 inner join WORKFLOW_MAP_PATH wmp on wmp.id=wmpp.ID
 inner join ACTIVITY_TEMPLATE at on at.ID = wmp.SOURCE_ID
 inner join WORKFLOW_MAP_ACTIVITY wma on wma.RELATED_ID= at.id
 where wma.source_id in (select id from workflow_map where is_current='1' and config_id in (select element_id from @res where [Group]='Workflow Map'))
union
-- 25.12) Path Post Event
select m.CONFIG_ID, 'Path post Event' as [Called By], m.name as method, '' as notes, m.METHOD_TYPE
 from METHOD m
 inner join WORKFLOW_MAP_PATH_POST wmpp on wmpp.RELATED_ID= m.id
 inner join WORKFLOW_MAP_PATH wmp on wmp.id=wmpp.ID
 inner join ACTIVITY_TEMPLATE at on at.ID = wmp.SOURCE_ID
 inner join WORKFLOW_MAP_ACTIVITY wma on wma.RELATED_ID= at.id
 where wma.source_id in (select id from workflow_map where is_current='1' and config_id in (select element_id from @res where [Group]='Workflow Map'))
union
--  25.13) Configurable Grid Event
select m.CONFIG_ID, 'Configurable Grid Event' as [Called By], m.name as method, cge.GRID_EVENT as notes, m.METHOD_TYPE
 from METHOD m
 inner join CONFIGURABLE_GRID_EVENT cge on cge.RELATED_ID = m.id
 where cge.SOURCE_ID in (select element_id from @res where [group]='Grid')
union
-- 25.14) Grid Column Event
select m.CONFIG_ID, 'Grid Column Event' as [Called By], m.name as method, ce.GRID_EVENT as notes, m.METHOD_TYPE
 from METHOD m
 inner join COLUMN_EVENT ce on ce.RELATED_ID = m.ID
 inner join GRID_COLUMN gc on gc.RELATED_ID=ce.SOURCE_ID
 where ce.SOURCE_ID in (select element_id from @res where [group]='Grid')

 
--declare @t2 table(sql_id char(32), caller  varchar(64), called varchar(64) )
declare @t2 table(id char(32), caller  varchar(64), called varchar(64) )
DECLARE Method_Cursor CURSOR FOR
SELECT distinct Name
FROM method

declare @this varchar(64)

OPEN Method_Cursor;

FETCH NEXT FROM Method_Cursor into @this;
WHILE @@FETCH_STATUS = 0
BEGIN

print @this

insert into @t2
     select distinct (select distinct config_id from [method] where name=@this), name ,  @this
     from [innovator].[method]
     where [innovator].[method].method_code like '%'+@this+'%'
        and [innovator].[method].name in (select distinct method from @t1)
        and @this!= [innovator].[method].name
        and not method.name is null       
FETCH NEXT FROM Method_Cursor into @this
     
END;

CLOSE Method_Cursor;
DEALLOCATE Method_Cursor;

insert into @t1
select distinct m.config_id, 'X Method' as [Called By], called as Method, 'called by: '+caller as Notes, m.method_type
 from @t2 t, method m
 where  not caller is  null
 and m.name=t.called
 
 delete from @t2
 
 declare @SQL_Items table (name varchar(64))
 
 insert into @SQL_Items
  select name from sql where TYPE in ('Procedure','Function')
  
 DECLARE Sql_Cursor CURSOR FOR
SELECT distinct Name
FROM @SQL_Items


OPEN Sql_Cursor;

FETCH NEXT FROM Sql_Cursor into @this;
WHILE @@FETCH_STATUS = 0
BEGIN

print @this

insert into @t2
     select distinct (select id from [SQL] where name=@this), method.name, @this
     from [innovator].[method]
     where [innovator].[method].method_code like '%'+@this+'%'
        and [innovator].[method].name in (select distinct method from @t1)
FETCH NEXT FROM SQL_Cursor into @this
     
END;

CLOSE SQL_Cursor;
DEALLOCATE SQL_Cursor; 
 
insert into @res
 --TODO somehow, t.Method contains the name of the ItemType instead of the Method name
 -- the query to method here works around that. 
 select distinct 'Method', (select name from method where config_id=t.method_id and is_current='1'), t.method_id, t.notes
 from @t1 t

insert into @res
 select distinct 'SQL', (select name from [SQL] where id= t.id), t.id, 'called_by'+t.called
 from @t2 t
 where not t.id in ('DF506B5C179A44AA96A2AAE0C58FD530') -- ignore core sql items
 
select r.[group],r.name,r.element_id, pd.name, r.comments
from innovator.PACKAGEDEFINITION pd
inner join innovator.PACKAGEGROUP pg on pg.SOURCE_ID=pd.ID
inner join innovator.PACKAGEELEMENT pe on pg.ID=pe.SOURCE_ID
right outer join @res r on pe.ELEMENT_ID =r.element_id

order by r.[group],r.name

end