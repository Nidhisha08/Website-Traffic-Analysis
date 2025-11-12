Use mavenfuzzyfactory;

select * from website_sessions;
select * from orders;
select * from website_pageviews;
select * from products;
select * from order_items;
select * from order_item_refunds;

#top result of traffic source;
# where the bulk of website session are coming from?
SELECT
	utm_source,
    utm_campaign,
    http_referer,
    count(DISTINCT website_session_id) AS session
FROM 
	website_sessions 
WHERE 
	created_at<'2012-04-12'
GROUP BY 
	utm_source,utm_campaign,http_referer
ORDER BY
	session DESC;


#Calculate the conversion rate from session to order of gserach non brand

SELECT
	count(s.website_session_id) AS session,
    count(order_id) AS orders,
    count(order_id)/count(s.website_session_id)*100 AS cnvrsn_rt_sesn_ordr
FROM
	website_sessions AS s
LEFT JOIN
	orders AS o
ON s.website_session_id=o.website_session_id
WHERE
	utm_source='gsearch' AND utm_campaign='nonbrand' AND s.created_at<'2012-04-14';
    
# result: Based on the paying for clicks we will need  a CVR  of at least 4%  to make number work If we are much lower, we will need to reduce bids
#If we're  higher, we can increase bids to more volume

# practice
select * from orders;

select
	primary_product_id,
    count(distinct case when items_purchased=1 then order_id else null end) as count_single_item_purchased,
    count(distinct case when items_purchased=2 then order_id else null end) as count_two_item_purchased
from
	orders
group by 
	primary_product_id;
    
    
# can you pull the gserach nonbrand trended session volume by week?
SELECT
	min(DATE(created_at)) as week_start_date,
	count(DISTINCT website_session_id) as session
FROM
	website_sessions
WHERE 
	created_at <'2012-05-10' AND utm_source='gsearch' AND utm_campaign='nonbrand'
GROUP BY WEEK(created_at), YEAR(created_at);

-- from the above result the gsearch nonbrand fairly sensitve to the bid chanages. we want to maximize the volume 
-- but dont want to spend more on ads then we can afford

-- could you pull coversion rate from session to order by deicve type?

SELECT
	device_type,
	count(DISTINCT w.website_session_id) AS session,
    count(DISTINCT order_id) AS orders,
     count(DISTINCT order_id)/count(DISTINCT w.website_session_id) AS cnvrn_rt
FROM
	website_sessions AS w
LEFT JOIN
	orders AS o
ON w.website_session_id=o.website_session_id
WHERE
	w.created_at<'2012-05-11' AND utm_source='gsearch' AND utm_campaign='nonbrand'
GROUP BY
	device_type;

# could you please pull weekely trends for both desktop and mobile gsearch nonbrand use till 2012-04-15

SELECT
	min(DATE(created_at)) AS week_start_date,
    count(CASE WHEN device_type='desktop' THEN website_session_id ELSE NULL END) AS dstop_session,
    count(CASE WHEN device_type='mobile' THEN website_session_id ELSE NULL END) AS mob_session
FROM
	website_sessions
WHERE 
	created_at BETWEEN '2012-04-15' AND '2012-06-09' AND utm_source='gsearch' AND utm_campaign='nonbrand'
GROUP BY
	WEEK(created_at),YEAR(created_at);
    
-- From this result we oberved that bid applied on gsearch nonbrand desktop on 2012-05-19 is effecting alter
-- number of website visitor are increased on biding. So fairly senstive to the bid changes


#could you please pull conversion rate from session to order by decive type;
-- means the customer who visted the website through our campaigns and purchesed the item
select * from website_sessions;
select * from orders;

select 
	device_type,
    count(w.website_session_id) as session, -- who visited the session
    count(o.website_session_id) as orders, -- who purchased the item
    count(o.website_session_id)/count(w.website_session_id) as conversion_rate
from 
	website_sessions as w
left join
	orders as o
on w.website_session_id=o.website_session_id
where w.created_at < '2012-05-11' and utm_source="gsearch" and utm_campaign="nonbrand"
group by
	device_type;

-- result- from the above result conversion rate on desktop is high than mobile on gsearch source and nonbrand campaigns.
-- so it's best idea to bid on gsearch nonbrand with desktop device.

-- next question
-- so we realised that desktop was doing well, so we bid our gsearch nonbrand desktop campaignsup on 2012-05-19
#let check the weekly trends for both desktop and mobile so we can see the impact of volume?

select
	min(date(created_at)) as week_start_date,
    count(case when device_type="mobile" then website_session_id else null end) as msession,
    count(case when device_type="desktop" then website_session_id else null end) as dtsession
from
	website_sessions
where
	created_at between '2012-04-15' and '2012-06-09'  and  utm_source="gsearch" and utm_campaign="nonbrand"
group by
	week(created_at), year(created_at);
    
-- result from the above result we bid on desktop so weekly volume was increased in desktop.



-- Could please pull the top view pages and rank using session
select
	pageview_url,
    count(distinct website_session_id) as session
from 
	website_pageviews
where
	created_at<'2012-06-09'
group by
	pageview_url
order by
	session desc;

-- could ou please pull the list of the top entry pages to our website and rank them with entry volume

with top_entry_detail as(
select
	website_session_id,
    min(website_pageview_id) as landeling_page
from
	 website_pageviews
where
	created_at<'2012-06-12'
group by
	website_session_id)

select
	pageview_url,
    count( distinct t.website_session_id) as no_of_visitor
from
	top_entry_detail as t
left join
	website_pageviews as w
on
	t.landeling_page=w.website_pageview_id
group by
	pageview_url
order by
	no_of_visitor desc;
    
-- from the above result all our traffic is landing to the home page 

#calculating the bounce rate
    
-- Now lets check how our landing page is performaning. Is customer purchasing the product. 
-- can you pull the bounce rate for traffic landing onthe homepage? requried column session, bounced session and % bounced_session

-- creating the table of first page entry of the visitor
-- counting the number of visitor entered to the first page
-- using order table count the number of order


create temporary table top_entry
select
	website_session_id,
    min(website_pageview_id) as min_landing_page
from
	website_pageviews
where
	created_at<'2012-06-14'
group by
	website_session_id;

create temporary table no_of_visitors
select
	 pageview_url,
	 t.website_session_id
from
	top_entry as t
left join
	website_pageviews as w
on
	t.min_landing_page=w.website_pageview_id;


create temporary table bounced_session
select
	n.website_session_id,
    n.pageview_url,
    count(w.website_pageview_id)  as count_of_page_view
from
	no_of_visitors as n
left join
	website_pageviews as w
on
	n.website_session_id=w.website_session_id
group by 
	n.website_session_id,
    n.pageview_url
having
	count_of_page_view=1;

select
	count(n.website_session_id) as session,
    count(count_of_page_view) as bounced_session,
    count(count_of_page_view)/count(n.website_session_id) as percentage_bounced_session
from
	no_of_visitors as n
left join
	bounced_session as b
on
	n.website_session_id=b.website_session_id;

-- result: bounce rate is 59% pretty high for paid search.

-- based on the analysis, they ran a new custom landing page (lander-1)50/50 against the homepage 
-- for gsearch non brand 

-- Can you pull the bounce rate  for two groups 

-- step1: for fair decision check the date of both page (/home and /landler-1) should be same
-- step2: find first time visiting to the pages
-- step3: cetagaries the no of visitors to the landing page
-- step4 find the bounced session who visited to the first page but not to next page
-- step5 : obtaind landing_page, session, bounced session and percentage of bounced session

select 
	* 
from 
	website_pageviews
where
	pageview_url='/lander-1';

-- so start from date 2012-06-19



create temporary table landing_page
select
	ws.website_session_id,
    min(website_pageview_id) as top_entry
from
	website_sessions as ws
inner join
	website_pageviews as wp
on 
	ws.website_session_id=wp.website_session_id
where
	ws.created_at between '2012-06-19' and '2012-07-28'
    and utm_source="gsearch"
    and utm_campaign="nonbrand"
group by
	website_session_id;
    


 create temporary table top_entering_page
select
	l.website_session_id,
    pageview_url
from 
	landing_page as l
left join
	website_pageviews as w
on
	l.top_entry=w.website_pageview_id
where
	pageview_url in('/lander-1','/home');



create temporary table first_page_entry
select
	t.website_session_id,
    t.pageview_url,
    count(w.website_pageview_id) as first_time_visited
from
	top_entering_page as t
left join
	website_pageviews as w
on
	t.website_session_id=w.website_session_id
group by
	t.website_session_id,t.pageview_url
having
	first_time_visited=1;
    
select
	t.pageview_url,
	count(t.website_session_id) as session,
    count(f.first_time_visited) as bounced_session,
    count(first_time_visited) /count(t.website_session_id) as percentage
from
	top_entering_page as t
left join
	first_page_entry as f
on
	t.website_session_id=f.website_session_id
group by
	pageview_url
order by
	percentage  desc;
    
-- result: /home has 58% of bounce rate and /lander-1 has 53% of bounce rate so there no much differences 
-- but /lander-1 performaming less bounce rate.	

-- could you please pull the volume of paid search nonbrand traffic landing on /home and /lander-1 
-- trended weekly since june 1st. Aso pull the overall paid search bounce rate trended weekly?

create temporary table first_landing_page
select
	ws.website_session_id,
    min(website_pageview_id) as top_entry
from
	website_sessions as ws
inner join
	website_pageviews as wp
on
	ws.website_session_id=wp.website_session_id
where
	utm_source="gsearch"
    and utm_campaign="nonbrand"
    and ws.created_at between "2012-06-01" and "2012-08-31"
group by
	ws.website_session_id;

create temporary table session_tab
select
	pageview_url as landing_page,
	f.website_session_id,
    created_at
from
	first_landing_page as f
left join
	website_pageviews as w
on
	top_entry=w.website_pageview_id
where
	pageview_url in("/home","/lander-1");

create temporary table bounce_session
select
	s.website_session_id,
    s.landing_page,
    count(w.website_pageview_id) as first_time_visited
from
	session_tab as s
left join
	website_pageviews as w
on
	s.website_session_id=w.website_session_id
group by
	s.website_session_id,s.landing_page
having
	first_time_visited=1;

select 
	min(created_at) as start_date_weekly,
    count(first_time_visited)/count(s.landing_page) as bounced_session,
	count(case when s.landing_page="/home" then 1 else null end) as home_session,
    count(case when s.landing_page="/lander-1" then 1 else null end) as lander_session
from
	session_tab as s
left join
	bounce_session as b
on
	s.website_session_id=b.website_session_id
group by
	week(created_at),year(created_at);
    
-- result: the bounce rate are slightly reduced after introducing the lander-1

-- Can you build the full conversion funnel, analyzing how many customers make it to each step.
-- start with /lander-1 build the funnel all the way to our thank you page  (gsearch nonbrand)
select * from website_pageviews where created_at>"2012-08-05";
select * from website_sessions;



select 
    count(case when pageview_url="/lander-1" then 1 else null end) as session,
    count(case when pageview_url="/products" then 1 else null end) as product_page,
    count(case when pageview_url="/the-original-mr-fuzzy" then 1 else null end) as mr_fuzzy_page,
    count(case when pageview_url="/cart" then 1 else null end) as cart_page,
    count(case when pageview_url="/shipping" then 1 else null end) as shipping_page,
    count(case when pageview_url="/billing" then 1 else null end) as billing_page,
    count(case when pageview_url="/thank-you-for-your-order" then 1 else null end) as order_page
from 
	website_sessions as ws
inner join
	website_pageviews as wp
on 
	ws.website_session_id=wp.website_session_id
where
	utm_source="gsearch" and utm_campaign="nonbrand"
    and ws.created_at>"2012-08-05"
    and ws.created_at<"2012-09-05";


    
create temporary table lander_1_pages
select
	website_session_id,
	max(product_page) as product_made_it,
    max(mr_fuzzy_page) as fuzzy_made_it,
    max(cart_page) as cart_made_it,
    max(shipping_page) as shipping_made_it,
    max(billing_page) as billing_made_it,
    max(order_page) as order_made_it
from
(select 
	ws.website_session_id,
    (case when pageview_url="/products" then 1 else 0 end) as product_page,
    (case when pageview_url="/the-original-mr-fuzzy" then 1 else 0 end) as mr_fuzzy_page,
    (case when pageview_url="/cart" then 1 else 0 end) as cart_page,
    (case when pageview_url="/shipping" then 1 else 0 end) as shipping_page,
    (case when pageview_url="/billing" then 1 else 0 end) as billing_page,
    (case when pageview_url="/thank-you-for-your-order" then 1 else 0 end) as order_page
from 
	website_sessions as ws
left join
	website_pageviews as wp
on 
	ws.website_session_id=wp.website_session_id
where
	utm_source="gsearch" and utm_campaign="nonbrand"
    and ws.created_at>"2012-08-05"
    and ws.created_at<"2012-09-05") as lander_1_page
group by
	website_session_id;
    
select
	count(website_session_id),
	count(distinct case when product_made_it=1 then website_session_id else null end) as a1,
    count(distinct case when fuzzy_made_it=1 then website_session_id else null end) as a2,
    count(distinct case when cart_made_it=1 then website_session_id else null end) as a3,
    count(distinct case when shipping_made_it=1 then website_session_id else null end) as a4,
    count(distinct case when billing_made_it=1 then website_session_id else null end) as a5,
    count(distinct case when order_made_it=1 then website_session_id else null end) as a6
from
	lander_1_pages;

	
-- they updated the billing page based on the funnel analysis. Can you see the whether billing-2 is 
-- doing better than billing-1

select * from website_pageviews;
select * from orders;

-- let me check from where the /billing-2 webpage introduced
select * from website_pageviews where pageview_url="/billing-2";

-- its started from "2012-09-10"

-- step 1: filter the data contain gsearch non brand and also filter the the dae range where both billing and billing-2 started
-- step 2: obtain the session_id whre the customer ordered and group by the page view_url
-- step3: count the number of session, customer visiting the the billing page and billing to order

select
	pageview_url as billing_session,
    count(billing_data.website_session_id) as session,
    count(order_id) as orders,
    count(order_id) /count(billing_data.website_session_id) as billing_to_order
from(
select
	ws.website_session_id,
    pageview_url
from
	website_sessions as ws
left join
	website_pageviews as wp
on
	ws.website_session_id=wp.website_session_id
where 
	wp.created_at> '2012-09-10' 
    and ws.created_at<'2012-11-10'
    and utm_source='gsearch'
    and utm_campaign='nonbrand'
    and pageview_url in("/billing", "/billing-2"))as billing_data
left join
	orders
on
	billing_data.website_session_id=orders.website_session_id
group by
	pageview_url

-- result: From the above result the /billing-2 has higly converting the customer comapered to the /billing
-- here we were tryinh to reduce the bounce rate and trying to improve thr billing to order conversion rate




