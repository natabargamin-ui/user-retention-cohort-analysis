SELECT
    ads.ad_date,
    ads.source,
    ads.campaign_name,
    ads.adset_name,

    CASE
        WHEN LOWER(SUBSTRING(ads.url_parameters FROM 'utm_campaign=([^&#]*)')) = 'nan'
            THEN NULL
        ELSE LOWER(url_decode(SUBSTRING(ads.url_parameters FROM 'utm_campaign=([^&#]*)')))
    END AS utm_campaign,

    SUM(ads.spend) AS total_spend,
    SUM(ads.clicks) AS total_clicks,
    SUM(ads.impressions) AS total_impressions,
    SUM(ads.reach) AS total_reach,
    SUM(ads.leads) AS total_leads,
    SUM(ads.value) AS total_value

FROM (
    SELECT
        fabd.ad_date,
        'Facebook' AS source,
        fc.campaign_name,
        fa.adset_name,
        fabd.url_parameters,
        COALESCE(fabd.spend, 0) AS spend,
        COALESCE(fabd.clicks, 0) AS clicks,
        COALESCE(fabd.impressions, 0) AS impressions,
        COALESCE(fabd.reach, 0) AS reach,
        COALESCE(fabd.leads, 0) AS leads,
        COALESCE(fabd.value, 0) AS value
    FROM facebook_ads_basic_daily fabd
    LEFT JOIN facebook_campaign fc
        ON fabd.campaign_id = fc.campaign_id
    LEFT JOIN facebook_adset fa
        ON fabd.adset_id = fa.adset_id

    UNION ALL

    SELECT
        gabd.ad_date,
        'Google' AS source,
        gabd.campaign_name,
        gabd.adset_name,
        gabd.url_parameters,
        COALESCE(gabd.spend, 0) AS spend,
        COALESCE(gabd.clicks, 0) AS clicks,
        COALESCE(gabd.impressions, 0) AS impressions,
        COALESCE(gabd.reach, 0) AS reach,
        COALESCE(gabd.leads, 0) AS leads,
        COALESCE(gabd.value, 0) AS value
    FROM google_ads_basic_daily gabd
) ads

GROUP BY
    ads.ad_date,
    ads.source,
    ads.campaign_name,
    ads.adset_name,
    CASE
        WHEN LOWER(SUBSTRING(ads.url_parameters FROM 'utm_campaign=([^&#]*)')) = 'nan'
            THEN NULL
        ELSE LOWER(url_decode(SUBSTRING(ads.url_parameters FROM 'utm_campaign=([^&#]*)')))
    END

ORDER BY
    ads.ad_date,
    ads.source,
    ads.campaign_name,
    ads.adset_name;