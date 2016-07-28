#include <iostream>
#include <krb5.h>
#include <errno.h>

using namespace std;

krb5_error_code
keytab_list(krb5_context k5,
                          krb5_keytab keytab,
                          krb5_boolean (* match_func) (krb5_context,
                                                       krb5_keytab_entry *,
                                                       void *) = NULL,
                          void *match_data = NULL)
{
	krb5_kt_cursor cursor;
	krb5_keytab_entry entry;
	krb5_error_code code;

	code = krb5_kt_start_seq_get (k5, keytab, &cursor);
	while(!code)
    {
		code = krb5_kt_next_entry (k5, keytab, &entry, &cursor);
		if (code == 0)
        {
            /* See if we should remove this entry */
            if (match_func && !match_func (k5, &entry, match_data)) {
                krb5_free_keytab_entry_contents (k5, &entry);
                continue;
            }

        }
	}

	if (code == KRB5_KT_END)
		code = 0;

	krb5_kt_end_seq_get (k5, keytab, &cursor);
	return code;
}

class krb5_base_object
{
protected:
    krb5_context _ctx;
    krb5_base_object(krb5_context ctx)
        : _ctx(ctx)
    {
    }
};

class principal : public krb5_base_object
{
    krb5_principal _handle;
    string _name;
public:
    principal(krb5_context ctx, const krb5_principal & h)
        : krb5_base_object(ctx), _handle(h)
    {
    }

    bool operator==(const principal & rhs) const
    {
        return (krb5_principal_compare(_ctx, _handle, rhs._handle) != 0);
    }
    const string & name() const
    {
        if(_name.empty())
        {
            char * output_name = NULL;
            if(krb5_unparse_name(_ctx, _handle, &output_name) == 0)
            {
                const_cast<principal*>(this)->_name = output_name;
                krb5_free_unparsed_name(_ctx, output_name);
            }
        }
        return _name;
    }
};

class timestamp
{
protected:
    krb5_timestamp _ts;
public:
    timestamp(krb5_timestamp timestamp=0)
        : _ts(timestamp) {}
    string to_string() const
    {
        char buf[32];
        if(krb5_timestamp_to_string(_ts, buf, sizeof(buf)) == 0)
            return buf;
        return string();
    }

    bool operator<(const timestamp & rhs) const
    {
        return _ts < rhs._ts;
    }
    bool operator==(const timestamp & rhs) const
    {
        return _ts == rhs._ts;
    }
    bool operator!=(const timestamp & rhs) const
    {
        return _ts == rhs._ts;
    }
};

class keytab : public krb5_base_object
{
    krb5_keytab _handle;
    bool _ok;
public:
    keytab(krb5_context ctx, const string & filename)
        : krb5_base_object(ctx), _handle(NULL), _ok(false)
    {
        if(!filename.empty())
        {
            krb5_error_code code = krb5_kt_resolve(_ctx, filename.c_str(), &_handle);
            _ok = (code == 0);
        }
    }
    ~keytab()
    {
        if(_handle)
            krb5_kt_close(_ctx, _handle);
    }

    bool valid() const
    {
        return _ok;
    }

    bool list()
    {
        bool ret = false;
        if(_ok)
        {
            krb5_kt_cursor cursor;
            krb5_keytab_entry entry;
            krb5_error_code code;

            code = krb5_kt_start_seq_get (_ctx, _handle, &cursor);
            while(!code)
            {
                code = krb5_kt_next_entry (_ctx, _handle, &entry, &cursor);
                if (code == 0)
                {
                    principal p(_ctx, entry.principal);
                    timestamp ts(entry.timestamp);

                    cout << "princ: " << p.name() << ", kvno " << entry.vno << ", time " << ts.to_string() << endl;
                }
            }

            if (code == KRB5_KT_END)
                code = 0;

            krb5_kt_end_seq_get (_ctx, _handle, &cursor);

        }
        return ret;
    }

    bool update(const keytab & source)
    {
        bool ret = false;
        if(source._ok)
        {
            krb5_kt_cursor cursor;
            krb5_keytab_entry entry;
            krb5_error_code code;
            code = krb5_kt_start_seq_get (source._ctx, source._handle, &cursor);
            while(!code)
            {
                code = krb5_kt_next_entry (source._ctx, source._handle, &entry, &cursor);
                if (code == 0)
                {
                    updateEntry(&entry);
                    
                    // release all memory
                    krb5_free_keytab_entry_contents(_ctx, &entry);
                }
            }

            if (code == KRB5_KT_END)
                code = 0;

            krb5_kt_end_seq_get (source._ctx, source._handle, &cursor);

            ret = true;
        }
        return ret;
    }

protected:
    krb5_error_code updateEntry(krb5_keytab_entry * updatedEntry)
    {
        krb5_kt_cursor cursor = NULL;
        krb5_keytab_entry entry;
        krb5_error_code code;
        bool add_princ = true;

        code = krb5_kt_start_seq_get (_ctx, _handle, &cursor);
        while(!code && add_princ)
        {
            code = krb5_kt_next_entry (_ctx, _handle, &entry, &cursor);
            if (code == 0)
            {
                if(krb5_principal_compare(_ctx, entry.principal, updatedEntry->principal) && entry.key.enctype == updatedEntry->key.enctype)
                {
                    if(entry.vno > updatedEntry->vno)
                    {
                        // newer key entry with higher kvno is already in the keytab
                        add_princ = false;
                    }
                    else if(entry.vno == updatedEntry->vno)
                    {
                        // found same kvno, so check timestamp
                        if(entry.timestamp >= updatedEntry->timestamp)
                        {
                            // same kvno but a new (or same) timestamp already in keytab
                            add_princ = false;
                        }
                    }
                }
                // release all memory
                krb5_free_keytab_entry_contents(_ctx, &entry);
            }
        }

        if (code == KRB5_KT_END)
            code = 0;
        if(cursor)
            krb5_kt_end_seq_get (_ctx, _handle, &cursor);
        if(add_princ)
            code = krb5_kt_add_entry(_ctx, _handle, updatedEntry);
        else
            code = 0;
        return code;
    }
};

int main(int argc, char ** argv)
{
    int ret = 0;
    cout << "usage: akt [source] [dest]" << endl;

    string source = (argc > 1) ? argv[1] : string();
    string dest = (argc > 2) ? argv[2] : string();

    krb5_context ctx;

    krb5_error_code code;
    code = krb5_init_context(&ctx);
    if(code != 0)
    {
        cerr << "Failed to initialize kerberos, error " << code << endl;
        ret = 1;
    }
    else
    {
        keytab sourceKeyTab(ctx, source);
        keytab destKeyTab(ctx, dest);

        cout << "sourceKeyTab" << endl;
        sourceKeyTab.list();

        destKeyTab.update(sourceKeyTab);
        cout << "new dest" << endl;
        destKeyTab.list();

        krb5_free_context(ctx);
    }

    return ret;
}
