# 04 — تصميم قاعدة البيانات

> مستنتج من أعمدة الإكسل. الأسماء بالإنجليزية للبرمجة، والوصف بالعربية.

## 1. مخطط العلاقات (نصي)

```
customers 1───* quotations 1───* quotation_lines
   │              │                    │
   │              1                    │ (paper, machine, finishings)
   │              │                    │
   │         production_orders *───* stock_moves (عبر paper_id)
   │              │
   └────* payments (سندات)
papers 1───* stock_moves | machines 1───* quotations/orders
products (قوالب) ──تُنسخ──> quotation_lines
settings (صف واحد) + lists (قوائم) + users + audit_log
```

## 2. الجداول

### 2.1 papers (قاعدة_الورق)
| العمود | النوع | ملاحظات |
|--------|-------|---------|
| id | SERIAL PK | |
| category | TEXT | الفئة: أوفست/كوشيه/NCR... (من lists) |
| paper_type | TEXT | النوع: أبيض/لامع/مطفي... |
| gsm | INT | الجرام |
| sheet_size | TEXT | افتراضي 100x70 |
| sheets_per_unit | INT | عدد الملائم 50x35 = 4 |
| sheet_price | NUMERIC(12,2) | سعر الفرخ |
| reorder_level | INT | حد إعادة الطلب |
| supplier | TEXT | المورد (نصي مؤقتاً) |
| is_active | BOOL | default true |
| UNIQUE(category, paper_type, gsm) | | منع التكرار |

### 2.2 machines (الماكينات)
| العمود | النوع | ملاحظات |
|--------|-------|---------|
| id | SERIAL PK | |
| name | TEXT UNIQUE | أوفست 50x35 / Epson / Sharp |
| kind | TEXT | Offset/Digital/Copier |
| waste_pct | NUMERIC(5,2) | الهالك % |
| hourly_cost | NUMERIC(12,2) | تكلفة التشغيل/ساعة |
| speed_per_hour | INT | السرعة فرخ/ساعة |
| status | TEXT | active/inactive |

### 2.3 products (قوالب المنتجات)
| العمود | النوع |
|--------|-------|
| id SERIAL PK | |
| name TEXT UNIQUE | كتاب A5... |
| category TEXT | كتب/دفاتر... |
| default_pages INT NULL | |
| default_ncr_copies INT NULL | |
| default_sheets_per_book INT NULL | أوراق/دفتر |
| default_books INT NULL | عدد الدفاتر |
| binding TEXT NULL | حراري/دبوس |
| pages_per_sheet INT | صفحات/فرخ (8 أو 4) |
| default_machine_id FK→machines | |
| default_paper_category TEXT | |
| default_paper_type TEXT | |

### 2.4 finishings (التشطيبات)
| العمود | النوع | ملاحظات |
|--------|-------|---------|
| id SERIAL PK | | |
| name TEXT UNIQUE | قص/طي/تدبيس... (12 خدمة) | |
| price NUMERIC(12,2) | يُدخل يدوياً | |
| unit TEXT | piece/thousand/job — **يُحسم بعد رفع الملف** | |

### 2.5 customers (العملاء)
| العمود | النوع |
|--------|-------|
| id SERIAL PK | |
| code TEXT UNIQUE | C-0001 تلقائي |
| name TEXT | |
| phone TEXT NULL | |
| address TEXT NULL | |
| opening_balance NUMERIC(14,2) default 0 | |

> إجمالي المبيعات/المدفوع/الرصيد تُحسب من quotations + payments (View).

### 2.6 quotations (عروض_الأسعار) + quotation_lines
**quotations:**
| العمود | النوع |
|--------|-------|
| id SERIAL PK | |
| number TEXT UNIQUE | Q-2026-0001 |
| date DATE | |
| customer_id FK | |
| status TEXT | draft/approved/rejected/cancelled |
| total_cost NUMERIC | مجموع التكاليف |
| total_amount NUMERIC | قيمة العرض |
| profit NUMERIC | الفرق |
| notes TEXT NULL | |
| created_by FK→users | |

**quotation_lines (سطر = سطر في محرك التسعير):**
| العمود | النوع | من عمود الإكسل |
|--------|-------|----------------|
| id SERIAL PK | | |
| quotation_id FK | | رقم العرض |
| product_id FK NULL | | المنتج |
| qty INT | | الكمية/الدفاتر |
| pages INT NULL | | عدد الصفحات |
| ncr_copies INT NULL | | نسخ NCR |
| sheets_per_book INT NULL | | أوراق/دفتر |
| books_count INT NULL | | عدد الدفاتر |
| colors TEXT NULL | | الألوان |
| plates_count INT default 0 | | البليتات |
| plate_cost NUMERIC default 0 | | تكلفة البليت |
| profit_margin_pct NUMERIC | | هامش الربح % |
| paper_id FK | | فئة+نوع الخامة |
| machine_id FK | | الماكينة |
| sheets_per_unit NUMERIC | | الملازم/وحدة (محسوب) |
| total_sheets NUMERIC | | إجمالي الأوراق (محسوب) |
| waste_pct NUMERIC | | الهالك % (محسوب) |
| paper_cost NUMERIC | | تكلفة الورق (محسوب) |
| run_hours NUMERIC | | ساعات التشغيل (محسوب) |
| machine_cost NUMERIC | | تكلفة الماكينة (محسوب) |
| finishing_ids INT[] / جدول وسيط | | التشطيب (متعدد) |
| finishing_cost NUMERIC | | تكلفة التشطيب (محسوب) |
| zinc_cost NUMERIC default 0 | | تكلفة الزنك (تُوضح بعد الرفع) |
| line_total_cost NUMERIC | | التكلفة الكلية |
| unit_price NUMERIC | | سعر الوحدة |
| line_amount NUMERIC | | قيمة البيع |
| price_snapshot JSONB | | نسخة أسعار وقت التسعير |

### 2.7 production_orders (أوامر_الإنتاج)
| العمود | النوع |
|--------|-------|
| id SERIAL PK | |
| number TEXT UNIQUE | PO-2026-0001 |
| date DATE | |
| quotation_id FK NULL | رقم العرض |
| customer_id FK | |
| product_id FK NULL | |
| qty INT | |
| machine_id FK | |
| paper_id FK | الخامة |
| sheets_required NUMERIC | الأوراق المطلوبة |
| sheets_with_waste NUMERIC | الأوراق مع الهالك |
| run_hours NUMERIC | ساعات التشغيل |
| cost NUMERIC | التكلفة |
| status TEXT | draft/approved/in_progress/done/cancelled |
| due_date DATE NULL | موعد التسليم |
| notes TEXT NULL | |

### 2.8 stock_moves (حركات_المخزون)
| العمود | النوع |
|--------|-------|
| id SERIAL PK | |
| number TEXT UNIQUE | SM-0001 |
| date DATE | |
| move_type TEXT | in/out/adjust (دخول/خروج/تسوية) |
| paper_id FK | الخامة |
| qty_sheets NUMERIC | الكمية (فرخ) |
| unit_price NUMERIC | سعر الوحدة |
| total_value NUMERIC | القيمة = الكمية×السعر |
| reference TEXT NULL | المرجع (رقم أمر/فاتورة) |
| supplier TEXT NULL | المورد |
| notes TEXT NULL | |

**View: stock_balance:** `paper_id, balance = SUM(in) − SUM(out) ± adjusts, avg_price, total_value`.

### 2.9 payments (المدفوعات — تُستكمل بعد الرفع)
| العمود المقترح | النوع |
|--------|-------|
| id, number (PAY-...), date, customer_id FK, amount, method (cash/transfer/credit), reference, notes | |

### 2.10 settings (الإعدادات — صف واحد id=1)
`sheet_size=100x70, unit_size=50x35, default_plate_price=1250, default_profit_margin_pct=30, work_hours_per_day=8, currency=ريال يمني, tax_pct=0, company_name, company_logo, header/footer...`

### 2.11 lists + users + audit_log
- **lists:** `(id, group, value, parent_group NULL, parent_value NULL, sort_order)` — للفئات والحالات والقوائم المعتمدة.
- **users:** `(id, username UNIQUE, password_hash, full_name, role, is_active)`.
- **audit_log:** `(id, user_id, action, table_name, record_id, old_values JSONB, new_values JSONB, created_at)`.

## 3. SQL أولي (PostgreSQL / يعمل على SQLite بتعديلات طفيفة)

```sql
CREATE TABLE papers (
  id SERIAL PRIMARY KEY,
  category TEXT NOT NULL, paper_type TEXT NOT NULL, gsm INT NOT NULL,
  sheet_size TEXT NOT NULL DEFAULT '100x70',
  sheets_per_unit INT NOT NULL DEFAULT 4,
  sheet_price NUMERIC(12,2) NOT NULL DEFAULT 0,
  reorder_level INT NOT NULL DEFAULT 0,
  supplier TEXT, is_active BOOLEAN NOT NULL DEFAULT TRUE,
  UNIQUE (category, paper_type, gsm)
);
CREATE TABLE machines (
  id SERIAL PRIMARY KEY, name TEXT UNIQUE NOT NULL, kind TEXT NOT NULL,
  waste_pct NUMERIC(5,2) NOT NULL DEFAULT 0,
  hourly_cost NUMERIC(12,2) NOT NULL DEFAULT 0,
  speed_per_hour INT NOT NULL DEFAULT 1, status TEXT NOT NULL DEFAULT 'active'
);
CREATE TABLE stock_moves (
  id SERIAL PRIMARY KEY, number TEXT UNIQUE NOT NULL, date DATE NOT NULL,
  move_type TEXT NOT NULL CHECK (move_type IN ('in','out','adjust')),
  paper_id INT NOT NULL REFERENCES papers(id),
  qty_sheets NUMERIC(12,2) NOT NULL, unit_price NUMERIC(12,2) NOT NULL DEFAULT 0,
  total_value NUMERIC(14,2) GENERATED ALWAYS AS (qty_sheets * unit_price) STORED,
  reference TEXT, supplier TEXT, notes TEXT
);
```

> باقي الجداول تُولد من نفس الحقول أعلاه عند بدء التنفيذ.
