INSERT INTO public.partner_score (
    result_month,
    result_year,
    store_code,
    partner_code,
    p_score,
    five_star,
    four_star,
    three_star,
    two_star,
    one_star
)
WITH FeedbackData AS (
    -- Your existing query for generating data
    SELECT
        EXTRACT(MONTH FROM (date + INTERVAL '7 hours'))::text AS result_month,
        EXTRACT(YEAR FROM (date + INTERVAL '7 hours'))::text AS result_year,
        store_code,
        trim(partner_code) as partner_code,
        CAST(AVG(CAST(rating AS DECIMAL(5, 2))) AS DECIMAL(5, 2)) AS p_score,
        SUM(CASE WHEN rating = '5' THEN 1 ELSE 0 END) AS five,
        SUM(CASE WHEN rating = '4' THEN 1 ELSE 0 END) AS four,
        SUM(CASE WHEN rating = '3' THEN 1 ELSE 0 END) AS three,
        SUM(CASE WHEN rating = '2' THEN 1 ELSE 0 END) AS two,
        SUM(CASE WHEN rating = '1' THEN 1 ELSE 0 END) AS one
    FROM
        persisted_feedback_app pfa
    WHERE
        status = 'Completed'
        AND LOWER(channel) = 'dine-in'
        AND "date" + INTERVAL '7 hour' >= '2023-09-01 00:00:00.000'
    GROUP BY
        partner_code,
        EXTRACT(MONTH FROM (date + INTERVAL '7 hours')),
        EXTRACT(YEAR FROM (date + INTERVAL '7 hours')),
        store_code
)
SELECT
    result_month,
    result_year,
    store_code,
    case 
        WHEN partner_code IS NULL THEN 'Unknown'
        ELSE partner_code
    end as partner_code,
    p_score,
    COALESCE(five, 0) AS five_star,
    COALESCE(four, 0) AS four_star,
    COALESCE(three, 0) AS three_star,
    COALESCE(two, 0) AS two_star,
    COALESCE(one, 0) AS one_star
FROM
    FeedbackData
ON CONFLICT (result_month, result_year, store_code, partner_code) DO UPDATE
SET
    p_score = EXCLUDED.p_score,
    five_star = EXCLUDED.five_star,
    four_star = EXCLUDED.four_star,
    three_star = EXCLUDED.three_star,
    two_star = EXCLUDED.two_star,
    one_star = EXCLUDED.one_star;