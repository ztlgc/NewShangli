ALTER TABLE public.account_book
ALTER COLUMN book_time DROP DEFAULT;

ALTER TABLE public.account_book
ALTER COLUMN book_time TYPE DATE
USING (
  CASE
    WHEN book_time IS NULL THEN CURRENT_DATE
    ELSE to_timestamp(book_time / 1000.0)::date
  END
);

ALTER TABLE public.account_book
ALTER COLUMN book_time SET DEFAULT CURRENT_DATE;

ALTER TABLE public.account_book
ALTER COLUMN book_time SET NOT NULL;
