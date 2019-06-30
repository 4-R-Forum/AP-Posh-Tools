declare @package_names_string varchar(max)
set @package_names_string = '{0}'

if exists (select * from sysobjects where name='PackageAudit' and xtype='U')
    drop table innovator.PackageAudit


declare @package_names TABLE (pd nvarchar(64))

-- split input parameter, adapted from http://rextester.com/ROAYWA64678
-- the example is a nifty use of sql xml to avoid more complicated code,
-- it is adapted for one-time use, no function required
	DECLARE @xml xml
	SET @xml = N'<root><r>' + replace(@package_names_string,',','</r><r>') + '</r></root>'
		INSERT INTO @package_names(pd)
	SELECT r.value('.','nvarchar(64)')
	FROM @xml.nodes('//root/r') as records(r)

create table innovator.PackageAudit
(
  element_type varchar(64) ,
  name varchar(64),
  element_id char(32),
  containing_package varchar(64),
  comments nvarchar(128)

)
declare @it varchar(64)

-- get list of itemtypes
insert into innovator.packageaudit
select 'ItemType', pe.name, pe.element_id , pd.name, 'ItemType in PackageDefinition'
from innovator.PACKAGEDEFINITION pd
inner join innovator.PACKAGEGROUP pg on pg.SOURCE_ID=pd.ID
inner join innovator.PACKAGEELEMENT pe on pg.ID=pe.SOURCE_ID
where pg.name='ItemType' and pd.name in (select pd from @package_names)

insert into innovator.packageaudit
select 'RelationshipType', pe.name, pe.element_id , pd.name, 'RelationshipType in PackageDefinition'
from innovator.PACKAGEDEFINITION pd
inner join innovator.PACKAGEGROUP pg on pg.SOURCE_ID=pd.ID
inner join innovator.PACKAGEELEMENT pe on pg.ID=pe.SOURCE_ID
inner join innovator.relationshiptype rt on rt.id =pe.element_id
where pg.name='RelationshipType' and pd.name in (select pd from @package_names)



DECLARE ItemType_Cursor CURSOR FOR

-- get list of itemtypes
select pe.element_id 
from innovator.PACKAGEDEFINITION pd
inner join innovator.PACKAGEGROUP pg on pg.SOURCE_ID=pd.ID
inner join innovator.PACKAGEELEMENT pe on pg.ID=pe.SOURCE_ID
where pg.name='ItemType' and pd.name in (select pd from @package_names)
union all
select rt.relationship_id 
from innovator.PACKAGEDEFINITION pd
inner join innovator.PACKAGEGROUP pg on pg.SOURCE_ID=pd.ID
inner join innovator.PACKAGEELEMENT pe on pg.ID=pe.SOURCE_ID
inner join innovator.relationshiptype rt on rt.id =pe.element_id
where pg.name='RelationshipType' and pd.name in (select pd from @package_names)


declare @this char(32)
OPEN ItemType_Cursor;

FETCH NEXT FROM ItemType_Cursor into @this;

WHILE @@FETCH_STATUS = 0
BEGIN
set @it='ItemType: '+ (select name from itemtype where id=@this)
print @it

insert into innovator.PackageAudit
exec [innovator].[SelectPackageElementForItemType] @this


        
FETCH NEXT FROM ItemType_Cursor into @this
     
END;

CLOSE ItemType_Cursor;
DEALLOCATE ItemType_Cursor;

select distinct * from PackageAudit
order by element_type,name