-- combining four tables. Extracting domain from emails of customers, joining it on subscriptions and 
-- events within those subscriptions, a example of sales query from online App Provider
WITH email_domains AS (
    SELECT SUBSTR(email, INSTR(email, '@') + 1) AS domain, account_id
    FROM accounts
)
SELECT 
    d.domain,
    COUNT(d.account_id) AS num_of_all_accounts,
    COUNT(s.subscription_id) AS num_of_paid_annual_subscriptions,
    SUM(s.price) AS total_monetary_value_in_EUR,
    COUNT(e.event_id) AS num_of_events
FROM 
    email_domains AS d
LEFT JOIN 
    subscriptions AS s 
ON 
	d.account_id = s.account_id
LEFT JOIN 
    events AS e 
ON 
	d.account_id = e.account_id
GROUP BY 
    d.domain
ORDER BY 
    total_monetary_value_in_EUR DESC;