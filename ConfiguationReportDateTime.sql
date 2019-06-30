/* all datetimes are in database time, UTC, until the final query returns values in CorporateTime */

/* Declarations */
Declare @PackageCompareDate datetime
Set @PackageCompareDate =  '{0}'
Declare @TimeZone varchar(50)
Set @TimeZone = '{1}'
Declare @Items Table (name varchar(64)) -- list of Item names
Declare @TableName varchar(64)          -- name of table to be passed to dynamic sql in cursor
Declare @d_sql as varchar(4096)         -- dynamic sql string
set @d_sql =''
Create  Table #Result (
  Package varchar(64) collate database_default,
  [Group] varchar(64) collate  database_default,
  keyed_name varchar(128)  collate   database_default,
  pe_id char(32)  collate database_default,
  id char (32),
  created_on datetime,
  modified_on datetime,
  core char(1)
  ) -- table to hold result

/* Create list of Items for cursor */
insert into  @Items
select instance_data
from innovator.itemtype where name in
 ('Action', 'Chart', 'Dashboard', 'EMail Message',
 'FileType', 'Form', 'Grid', 'Identity', 'ItemType',
 'Life Cycle Map', 'List', 'Method', 'Permission',
 'RelationshipType', 'Report', 'Revision', 'Sequence',
 'Variable', 'Vault', 'Viewer', 'Workflow Map', 'SQL', 'PM_ProjectGridLayout','UserMessage'
)

/* Declare the cursor to take ItemTypes one by one */
DECLARE nip_cursor CURSOR FOR 
select name from @Items

/* open the cursor and get first Item */
OPEN nip_cursor

FETCH NEXT FROM nip_cursor 
INTO @TableName

/* Run the loop */
WHILE @@FETCH_STATUS = 0
BEGIN
  /* create the dynamic sql to find Modified in Package*/
set @d_sql='Insert #Result ' 
set @d_sql = @d_sql + 'select distinct pd.name as Package, i.name as [Group] , t.keyed_name, '
set @d_sql = @d_sql + 'case i.is_versionable when ''1'' then t.config_id else t.id end as pe_id, pe.id, '
set @d_sql = @d_sql + 'case i.is_versionable when ''1'' then (select max(created_on) from innovator.['+ @TableName+'] where config_id= t.config_id) else t.created_on end as created_on, '
set @d_sql = @d_sql + 'case i.is_versionable when ''1'' then (select max(isnull(modified_on,created_on)) from innovator.['+ @TableName+'] where config_id= t.config_id) else isnull(t.modified_on,t.created_on) end as modified_on,'
set @d_sql = @d_sql + 'case i.name when ''ItemType'' then (select core from innovator.itemtype where name=t.name) when ''RelationshipType'' then (select core from innovator.relationshiptype where name=t.name) else null end as core'
set @d_sql = @d_sql + '  from innovator.ItemType i ,'
set @d_sql = @d_sql + '         innovator.['+ @TableName+'] t'
set @d_sql = @d_sql + ' inner join innovator.PACKAGEELEMENT pe on pe.element_id=t.id'
set @d_sql = @d_sql + ' inner join innovator.packageGroup pg on pg.id = pe.source_id'
set @d_sql = @d_sql + ' inner join  innovator.PACKAGEDEFINITION pd on pd.id =pg.source_id'
set @d_sql = @d_sql + ' where i.instance_data = ''' + @TableName +'''' 
set @d_sql = @d_sql + ' and case i.is_versionable when ''1'' then (select max(isnull(modified_on,created_on)) from innovator.['+ @TableName+'] where config_id= t.config_id) else isnull(t.modified_on,t.created_on) end > ''' +convert( varchar(64),@PackageCompareDate, 120) +''''
If @TableName='ItemType'
  set @d_sql = @d_sql + ' and (not t.is_relationship= ''1'') '
 print @d_sql 
  Exec (@d_sql)

  /* create the dynamic sql to find Relationship ItemType modified where RelationshipType not modified */
set @d_sql='Insert #Result '   
set @d_sql = @d_sql + 'select distinct ' 
set @d_sql = @d_sql + '   pd.name asPackage'
set @d_sql = @d_sql + ' , i.name+ '' (ItemType)'' as [Group] '
set @d_sql = @d_sql + ' , t.keyed_name , t.id as [pe_id], pe.id'
set @d_sql = @d_sql + ' , t.created_on '
set @d_sql = @d_sql + ' , isnull(rit.modified_on,rit.created_on)  as modified_on '
set @d_sql = @d_sql + ' ,(select core from innovator.relationshiptype where name=t.name) as core '
set @d_sql = @d_sql + '  from innovator.ItemType i , '
set @d_sql = @d_sql + '  innovator.[RELATIONSHIPTYPE] t '
set @d_sql = @d_sql + '   inner join innovator.PACKAGEELEMENT pe on pe.element_id=t.id '
set @d_sql = @d_sql + '   inner join innovator.packageGroup pg on pg.id = pe.source_id '
set @d_sql = @d_sql + '   inner join  innovator.PACKAGEDEFINITION pd on pd.id =pg.source_id '
set @d_sql = @d_sql + '   inner join innovator.ITEMTYPE rit on rit.ID = t.RELATIONSHIP_ID '
set @d_sql = @d_sql + '  where i.instance_data = ''RELATIONSHIPTYPE'' '
set @d_sql = @d_sql + '     and isnull(rit.modified_on,rit.created_on)  > ''' +convert( varchar(64),@PackageCompareDate, 120) +'''' 
set @d_sql = @d_sql + '     and not isnull(t.modified_on,t.created_on)  > ''' +convert( varchar(64),@PackageCompareDate, 120) +'''' 
set @d_sql = @d_sql + '     and not t.id in (select id from #Result where [Group] like ''RelationshipType%'')'
 print @d_sql 
  Exec (@d_sql)  
  /* create the dynamic sql to find NOT in PACKAGE*/
  
set @d_sql='' 
set @d_sql = @d_sql + 'insert into #Result '
set @d_sql = @d_sql + 'select distinct ''x_NOT_in_package'' as [Package], i.name as [Group] , t.keyed_name, '
set @d_sql = @d_sql + 'case i.is_versionable when ''1'' then t.config_id else t.id end as [pe_id], null as [id],'
set @d_sql = @d_sql + 'case i.is_versionable when ''1'' then (select max(created_on) from innovator.['+ @TableName+'] where config_id= t.config_id
and config_id not in (select id from #Result)) else t.created_on end as created_on, '
set @d_sql = @d_sql + 'case i.is_versionable when ''1'' then (select max(modified_on) from innovator.['+ @TableName+'] where config_id= t.config_id
and config_id not in (select id from #Result)) else t.modified_on end as modified_on,'
set @d_sql = @d_sql + 'case i.name when ''ItemType'' then (select core from innovator.itemtype where name=t.name) when ''RelationshipType'' then (select core from innovator.relationshiptype where name=t.name) else null end as core'
set @d_sql = @d_sql + '  from innovator.['+ @TableName + '] t, '
set @d_sql = @d_sql + '  innovator.itemtype i ' 
set @d_sql = @d_sql + '  where i.instance_data = '''+@TableName +'''' 
set @d_sql = @d_sql + '  and case i.is_versionable when ''1'' then (select max(modified_on) from innovator.['+ @TableName+'] where config_id= t.config_id
and config_id not in (select id from #Result)) else t.modified_on end > ''' +convert( varchar(64),@PackageCompareDate, 120) +''''
set @d_sql = @d_sql + '  and case i.is_versionable when ''1'' then t.config_id else t.id end not in '
set @d_sql = @d_sql + '  ('
set @d_sql = @d_sql + '  SELECT'
set @d_sql = @d_sql + '    innovator.PACKAGEELEMENT.ELEMENT_ID AS id'
set @d_sql = @d_sql + '  FROM innovator.PACKAGEDEFINITION'
set @d_sql = @d_sql + '    INNER JOIN innovator.PACKAGEGROUP'
set @d_sql = @d_sql + '      ON innovator.PACKAGEDEFINITION.ID = innovator.PACKAGEGROUP.SOURCE_ID'
set @d_sql = @d_sql + '    INNER JOIN innovator.PACKAGEELEMENT'
set @d_sql = @d_sql + '      ON innovator.PACKAGEGROUP.ID = innovator.PACKAGEELEMENT.SOURCE_ID'
set @d_sql = @d_sql + ')'
If @TableName='Permission'
  set @d_sql = @d_sql + '  and not t.is_private=''1'' '
If @TableName='ItemType'
  set @d_sql = @d_sql + '  and not t.is_relationship=''1''  '
If @TableName='Identity'
  set @d_sql = @d_sql + '  and not t.is_alias=''1''  '
 print @d_sql 

  Exec (@d_sql) 
  
  
  /* get next Item */
  FETCH NEXT FROM nip_cursor 
  INTO @TableName
END

/* clean up  and return result*/
CLOSE nip_cursor
DEALLOCATE  nip_cursor

delete from #Result where modified_on  < @PackageCompareDate

   CREATE TABLE #ITEM_INSTANCES
    ( 
        tablename VARCHAR(64) collate database_default, 
        rc INT 
    ) 

declare @itemtypes table (name varchar(64) collate database_default)
insert into @itemtypes select keyed_name from #RESULT where [Group] in ('ItemType','RelationshipType') and  not keyed_name in ('Search Center')

DECLARE rowcount_cursor CURSOR FOR 
select name from @ItemTypes

/* open the cursor and get first Item */
OPEN rowcount_cursor

FETCH NEXT FROM rowcount_cursor 
INTO @TableName

/* Run the loop */
WHILE @@FETCH_STATUS = 0
BEGIN
  /* create the dynamic sql to find Modified in Package*/
set @d_sql='Insert #ITEM_INSTANCES '
set @d_sql = @d_sql + 'select '''+@TableName+''', 0'

--count(id) from [' + replace(@TableName,' --','_') + '])  '
Exec (@d_sql)
print @d_sql

 /* get next Item */
  FETCH NEXT FROM rowcount_cursor 
  INTO @TableName
END

/* clean up  and return result*/
CLOSE rowcount_cursor
DEALLOCATE  rowcount_cursor

select distinct
  r.Package ,
  r.[Group] ,
  r.keyed_name ,
  pe_id as [ElementId],
  r.id ,
  innovator.convertToLocal(r.created_on, @TimeZone) created_on, --convert to Corporate Time
  innovator.convertToLocal(modified_on, @TimeZone) modified_on --convert to Corporate Time
  --core,
  --case when r.[group] ='ItemType' or r.[group] = 'RelationshipType' then
  -- (select rc from #ITEM_INSTANCES where tablename= replace(r.keyed_name,' ','_'))
  --  else null end as rows
from #Result r
where innovator.convertToLocal(modified_on, @TimeZone) > @PackageCompareDate
order by r.Package,r.[Group], r.keyed_name

drop table #Result
drop table #ITEM_INSTANCES