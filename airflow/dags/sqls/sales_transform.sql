with m_nationality as 
(select tu.storecode,ms.storename,tu.date,tu.checkno,left(tu.guestattribute,2) as nationalitycode,mz.attributename as nationality
,concat(tu.storecode,'-',tu.orderno,'-',tu.date) as feedback_id 
from t_uriageh tu 
left join m_zokusei mz on(left(tu.guestattribute,2)=mz.attributecode and tu.storecode =mz.storecode )
left join m_store ms on (ms.storecode=tu.storecode)
where left(tu.guestattribute,2) not in ('00')
union all
select tu.storecode,ms.storename,tu.date,tu.checkno,left(tu.guestattribute,2) as nationalitycode,
case 
	when left(tu.guestattribute,2)='00' then 'Other'
end as nationality,
concat(tu.storecode,'-',tu.orderno,'-',tu.date) as feedback_id 
from t_uriageh tu 
left join m_zokusei mz on(left(tu.guestattribute,2)=mz.attributecode and tu.storecode =mz.storecode )
left join m_store ms on (ms.storecode=tu.storecode)
where left(tu.guestattribute,2) in ('00')),
m_orderby as
(select 
orderby,
date,
storecode,
orderno
from t_jutyum tj
where tj.orderturn = '1' 
and tj.orderline = '1'
),
m_vouchersale as 
(select storecode,sum(totalwithoutvat) as vouchersale,"date",checkno,orderno  from t_uriagem
where itemcode like '9988%'
--or itemcode ='99000060'
group by storecode,date, checkno, orderno)
INSERT INTO t_sales_transform (
    id,
    storecode,
    storename,
    city,
    date,
    weekday,
    tablestarttime,
    cashsaletime,
    checkno,
    guest,
    nationality,
    feedback_id,
    totalbyprice,
    totalwithoutvat,
    itemdiscountbyprice,
    itemdiscountwithoutvat,
    billdiscountbyprice,
    billdiscountwithoutvat,
    vouchersale,
    taxexclude,
    taxinclude,
    voucher,
    credit,
    accountreceivable,
    emoney,
    other,
    cash,
    totalamount,
    orderno,
    tableno,
    isdelete,
    orderbyfirstturn,
    tabletype,
    servicetype,
    updated_at
)
SELECT
    concat(tu.storecode, tu.date, tu.checkno) as id,
    tu.storecode,
    concat(tu.storecode::text, '-', ms.shortname) as storename,
    CASE
        WHEN ms.city IN ('SGN', 'BDG') THEN '(VN)SOUTH'
        WHEN ms.city IN ('HAN', 'HPH') THEN '(VN)NORTH'
        WHEN ms.city IN ('CXR', 'DAN') THEN '(VN)CENTRAL'
        WHEN ms.city IN ('PNH') THEN '(KH)CAMBODIA'
        WHEN ms.city IN ('BGL') THEN '(IN)INDIA'
        WHEN ms.city IN ('TYO') THEN '(JP)JAPAN'
    END AS city,
    tu.date::date,
    to_char(tu.date::date, 'Day') AS weekday,
    tu.tablestarttime,
    tu.systemtime AS cashsaletime,
    tu.checkno,
    tu.guest,
    mn.nationality,
    mn.feedback_id,
    tu.totalbyprice,
    tu.totalwithoutvat,
    tu.itemdiscountbyprice,
    tu.itemdiscountwithoutvat,
    tu.billdiscountbyprice,
    tu.billdiscountwithoutvat,
    CASE
        WHEN a.vouchersale IS NULL THEN '0'
        ELSE a.vouchersale
    END AS vouchersale,
    tu.taxexclude,
    tu.taxinclude,
    tu.voucher,
    tu.credit,
    tu.accountreceivable,
    tu.emoney,
    tu.other,
    tu.cash,
    tu.totalamount,
    tu.orderno,
    tu.tableno,
    t.isdelete,
    CASE
        WHEN COALESCE((mo.orderby), '0') = '0' THEN 'POS'
        WHEN COALESCE((mo.orderby), '0') = '5' THEN 'Handy'
        WHEN COALESCE((mo.orderby), '0') = '6' THEN 'TTO'
        WHEN COALESCE((mo.orderby), '0') IN ('8', '9') THEN '4P''s Delivery'
        WHEN COALESCE((mo.orderby), '0') = 'B' THEN 'Capichi BYOD'
        WHEN COALESCE((mo.orderby), '0') = 'D' THEN 'Capichi Delivery'
        WHEN COALESCE((mo.orderby), '0') = 'O' THEN '4P''s BYOD'
        ELSE 'Unknown'
    END AS orderbyfirstturn,
    CASE
        WHEN sk.tabletype = '0' THEN 'Dine-in'
        WHEN sk.tabletype = '1' THEN 'Take-away'
        WHEN sk.tabletype = '2' THEN 'Delivery'
    END AS tabletype,
    CASE
        WHEN tu.storecode LIKE '005%' THEN 'Delivery Hub'
        WHEN tu.storecode LIKE '002%' THEN 'Cafe'
        WHEN (tu.storecode = '001023' AND tu.posno = '003') THEN 'Pizza Land'
        WHEN (tu.storecode = '001017' AND tu.posno = '003') THEN 'Bar'
        ELSE 'Restaurant'
    END AS servicetype,
    tu.update - INTERVAL '7 hour' AS updated_at
FROM
    t_uriageh tu
LEFT JOIN m_store ms ON (tu.storecode = ms.storecode)
LEFT JOIN t_uriageh t ON (tu.storecode = t.storecode AND tu.date = t.date AND tu.checkno = t.checkno)
LEFT JOIN m_seki sk ON (tu.storecode = sk.storecode AND tu.tableno = sk.tableno)
LEFT JOIN m_nationality mn ON (tu.date = mn.date AND tu.checkno = mn.checkno AND tu.storecode = mn.storecode)
LEFT JOIN m_orderby mo ON (tu.storecode = mo.storecode AND tu.date = mo.date AND tu.orderno = mo.orderno)
LEFT JOIN m_vouchersale a ON (a.storecode = tu.storecode AND a.checkno = tu.checkno AND a.date = tu.date AND a.orderno = tu.orderno)
WHERE
    tu.date >= '20240101' 
    --tu.date::date = current_date - interval '1 day'
ON CONFLICT (id) DO UPDATE
SET
    storecode = EXCLUDED.storecode,
    storename = EXCLUDED.storename, 
    city = EXCLUDED.city,
    date = EXCLUDED.date,
    weekday = EXCLUDED.weekday,
    tablestarttime = EXCLUDED.tablestarttime,
    cashsaletime = EXCLUDED.cashsaletime,
    checkno = EXCLUDED.checkno,
    guest = EXCLUDED.guest,
    nationality = EXCLUDED.nationality,
    feedback_id = EXCLUDED.feedback_id,
    totalbyprice = EXCLUDED.totalbyprice,
    totalwithoutvat = EXCLUDED.totalwithoutvat,
    itemdiscountbyprice = EXCLUDED.itemdiscountbyprice,
    itemdiscountwithoutvat = EXCLUDED.itemdiscountwithoutvat,
    billdiscountbyprice = EXCLUDED.billdiscountbyprice,
    billdiscountwithoutvat = EXCLUDED.billdiscountwithoutvat,
    vouchersale = EXCLUDED.vouchersale,
    taxexclude = EXCLUDED.taxexclude,
    taxinclude = EXCLUDED.taxinclude,
    voucher = EXCLUDED.voucher,
    credit = EXCLUDED.credit,
    accountreceivable = EXCLUDED.accountreceivable,
    emoney = EXCLUDED.emoney,
    other = EXCLUDED.other,
    cash = EXCLUDED.cash,
    totalamount = EXCLUDED.totalamount,
    orderno = EXCLUDED.orderno,
    tableno = EXCLUDED.tableno,
    isdelete = EXCLUDED.isdelete,
    orderbyfirstturn = EXCLUDED.orderbyfirstturn,
    tabletype = EXCLUDED.tabletype,
    servicetype = EXCLUDED.servicetype,
    updated_at = EXCLUDED.updated_at;