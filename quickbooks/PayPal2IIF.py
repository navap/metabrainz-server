#!/usr/bin/env python

b = '''
Input:

Date     Time    Time Zone       Name    Type    Status  Currency        Gross   Fee     Net     From Email Address      To Email Address        Transaction ID  Shipping Address  Address Status  Item Title      Item ID         Shipping and Handling Amount    Insurance Amount        Sales Tax       Option 1 Name   Option 1
Value    Option 2 Name   Option 2 Value  Auction Site    Buyer ID        Item URL        Closing Date    Reference Txn ID        Invoice Number  Custom Number   Receipt ID        Balance         Contact Phone Number
"6/28/2005"     "12:42:01"      "PDT"   "Steve Jinks"   "Web Accept Payment Received"   "Completed"     "USD"   "10.00" "-0.69" "9.31"  "Steve@e-jinks.net"     "donations@musicbrainz.org"       "7V808331G80193445"     ""      ""      "10 Dollar Donation to MusicBrainz"     "TEN_BUCKS"     "0.00"  ""      "0.00"  ""      ""        ""      ""      ""      ""      ""      ""      ""      ""      ""      ""      "974.79"        ""
'''

a = '''
Output:

!TRNS   DATE    ACCNT   NAME    CLASS   AMOUNT  MEMO
!SPL    DATE    ACCNT   NAME    AMOUNT  MEMO
!ENDTRNS
TRNS    "2/28/2005"     "Account - Bank - PayPal"       "Benjamin Woodacre"     "Web Accept Payment Received"   9.41    "10 Dollar Donation to MusicBrainz"
SPL     "2/28/2005"     "Income - Donations - PayPal"   "Benjamin Woodacre"     -10.00
SPL     "2/28/2005"     "Expense - Bank - PayPal"       Fee     0.59
'''

import sys, os

senderPayPalMoneyMarket = 'PayPal - Money Market'
senderBankAccount = 'Bank Account'

expenseAccountPayPal = 1
expenseAccounts = ("Expense - Hosting - CCCP",
                   "Expense - Bank - PayPal",
                   "Expense - Hardware",
                   "Expense - Development",
                   "Expense - Marketing",
                   "Expense - Internet",
                   "Expense - Travel",
                   "Expense - Supplies")

incomeAccountDonation = 0
incomeAccountInterest = 1
incomeAccounts = ("Income - Donations - PayPal", 
                  "Income - Bank - Interest",
                  "Income - Licenses - Live Data F")

bankAccountHOB = 0
bankAccountPayPal = 1
bankAccounts = ("Account - Bank - HOB Checking", 
                "Account - Bank - PayPal")

def selectExpenseAccount():
    index = 1
    print "0) Skip this transaction"
    for acc in expenseAccounts:
        print "%d) %s" % (index, acc)
        index += 1

    while True:
        x = None
        try:
            x = int(raw_input("select account> "))
        except ValueError:
            print "Invalid selection"
            continue

        x -= 1
        if x >= -1 and x < len(expenseAccounts):
            break

    return x

def selectIncomeAccount():
    index = 1
    print "0) Skip this transaction"
    for acc in incomeAccounts:
        print "%d) %s" % (index, acc)
        index += 1

    while True:
        x = None
        try:
            x = int(raw_input("select account> "))
        except ValueError:
            print "Invalid selection"
            continue

        x -= 1
        if x >= -1 and x < len(incomeAccounts):
            break

    return x

def toFloat(svalue):
    return float(svalue.replace(",", ""))
                  
def income(data, out, gross):
    '''called when we have income to write'''

    if data['Type'].find('Payment') == -1 and data['Type'].find('Dividend') == -1:
        print "Received some other type of credit: %s, %s, %.2f, %s" % (data['Date'], data['Name'], gross, data['Type'])
        print "Which account should be credited:"
        x = selectIncomeAccount()
        if x == -1: return
        account = incomeAccounts[x] 
        out.write('TRNS\t"%s"\t"Account - Bank - PayPal"\t"%s"\t"%s"\t%s\t"%s"\n' % (data['Date'], data['Name'], data['Type'], data['Net'], data['Item Title']))
        out.write('SPL\t"%s"\t"%s"\t"%s"\t%.2f\n' % (data['Date'], account, data['Name'], -gross))
        # Print out the Fee SPL, if any
        if data["Fee"] and toFloat(data["Fee"]) < 0.0:
            account = expenseAccounts[expenseAccountPayPal]
            fee = abs(toFloat(data["Fee"]))
            out.write('SPL\t"%s"\t"%s"\tFee\t%.2f\n' % (data['Date'], account, fee))
        out.write('ENDTRNS\n')
        return

    if data['Name'] == senderPayPalMoneyMarket:
        account = incomeAccounts[incomeAccountInterest]
    else:
        account = incomeAccounts[incomeAccountDonation]

    out.write('TRNS\t"%s"\t"Account - Bank - PayPal"\t"%s"\t"%s"\t%s\t"%s"\n' % (data['Date'], data['Name'], data['Type'], data['Net'], data['Item Title']))
    out.write('SPL\t"%s"\t"%s"\t"%s"\t%.2f\n' % (data['Date'], account, data['Name'], -gross))

    # Print out the Fee SPL, if any
    if data["Fee"] and toFloat(data["Fee"]) < 0.0:
        account = expenseAccounts[expenseAccountPayPal]
        fee = abs(toFloat(data["Fee"]))
        out.write('SPL\t"%s"\t"%s"\tFee\t%.2f\n' % (data['Date'], account, fee))

    out.write('ENDTRNS\n')

def expense(data, out, gross):
    '''called when we have an expense to write'''

    if data['Name'] == senderBankAccount:
        account = bankAccounts[bankAccountHOB]  
    else:
        print "Received some other type of debit: %s, %s, %.2f, %s" % (data['Date'], data['Name'], gross, data['Type'])
        print "Which account should be debited:"
        x = selectExpenseAccount()
        if x == -1: return
        account = expenseAccounts[x] 
    
    out.write('TRNS\t"%s"\t"Account - Bank - PayPal"\t"%s"\t"%s"\t%s\t"%s"\n' % (data['Date'], data['Name'], data['Type'], data['Net'], data['Item Title']))
    out.write('SPL\t"%s"\t"%s"\t"%s"\t%.2f\n' % (data['Date'], account, data['Name'], abs(gross)))
    out.write('ENDTRNS\n')

lineNum = 1
fp = None
try:
    fp = open(sys.argv[1], "r")
except IOError:
    print "Cannot open input file %s" % sys.argv[1]
    exit(0)

out = None
try:
    out = open(sys.argv[2], "w")
except IOError:
    print "Cannot open output file %s" % sys.argv[2]
    exit(0)

header = fp.readline()
headerCols = [ x.strip() for x in header.split('\t') ]

out.write('!TRNS\tDATE\tACCNT\tNAME\tCLASS\tAMOUNT\tMEMO\n')
out.write('!SPL\tDATE\tACCNT\tNAME\tAMOUNT\tMEMO\n')
out.write('!ENDTRNS\n')

for line in fp.readlines():
    cols = line.split('\t')
    index = 0
    data = {}
    for col in cols:
        if col[0] == '"': col = col[1:len(col) - 1]
        data[headerCols[index]] = col
        index += 1

    # Skip over pending transactions
    if data['Status'] == 'Pending': 
        print "Skipping: %s - %s - %s" % (data['Name'], data['Gross'], data['Status'])
        continue

    gross = toFloat(data['Gross'])
    if gross > 0.0:
        income(data, out, gross)
    else:
        expense(data, out, gross)


    lineNum+=1

fp.close()
out.close()

