```javascript
import i18next from 'i18next';
import { initReactI18next } from 'react-i18next';

i18next.use(initReactI18next).init({
  resources: {
    en: {
      translation: {
        pointsBalance: {
          title: 'Your Points Balance',
          ariaLabel: 'View points balance',
          points: '{count, number} Stars',
          loading: 'Loading points...',
        },
        errors: {
          title: 'Error',
          unauthorized: 'Unable to load balance: Unauthorized',
          notFound: 'Unable to load balance: Not found',
          generic: 'Unable to load balance',
          updateFailed: 'Failed to update points balance',
        },
      },
    },
    es: {
      translation: {
        pointsBalance: {
          title: 'Tu Saldo de Puntos',
          ariaLabel: 'Ver saldo de puntos',
          points: '{count, number} Estrellas',
          loading: 'Cargando puntos...',
        },
        errors: {
          title: 'Error',
          unauthorized: 'No se pudo cargar el saldo: No autorizado',
          notFound: 'No se pudo cargar el saldo: No encontrado',
          generic: 'No se pudo cargar el saldo',
          updateFailed: 'Error al actualizar el saldo de puntos',
        },
      },
    },
    de: {
      translation: {
        pointsBalance: {
          title: 'Ihr Punktestand',
          ariaLabel: 'Punktestand anzeigen',
          points: '{count, number} Sterne',
          loading: 'Punkte werden geladen...',
        },
        errors: {
          title: 'Fehler',
          unauthorized: 'Punktestand konnte nicht geladen werden: Unautorisiert',
          notFound: 'Punktestand konnte nicht geladen werden: Nicht gefunden',
          generic: 'Punktestand konnte nicht geladen werden',
          updateFailed: 'Fehler beim Aktualisieren des Punktestands',
        },
      },
    },
    ja: {
      translation: {
        pointsBalance: {
          title: 'あなたのポイント残高',
          ariaLabel: 'ポイント残高を表示',
          points: '{count, number} スター',
          loading: 'ポイントを読み込み中...',
        },
        errors: {
          title: 'エラー',
          unauthorized: 'ポイント残高を読み込めませんでした：認証エラー',
          notFound: 'ポイント残高を読み込めませんでした：見つかりません',
          generic: 'ポイント残高を読み込めませんでした',
          updateFailed: 'ポイント残高の更新に失敗しました',
        },
      },
    },
    fr: {
      translation: {
        pointsBalance: {
          title: 'Votre Solde de Points',
          ariaLabel: 'Voir le solde des points',
          points: '{count, number} Étoiles',
          loading: 'Chargement des points...',
        },
        errors: {
          title: 'Erreur',
          unauthorized: 'Impossible de charger le solde : Non autorisé',
          notFound: 'Impossible de charger le solde : Non trouvé',
          generic: 'Impossible de charger le solde',
          updateFailed: 'Échec de la mise à jour du solde des points',
        },
      },
    },
    pt: {
      translation: {
        pointsBalance: {
          title: 'Seu Saldo de Pontos',
          ariaLabel: 'Ver saldo de pontos',
          points: '{count, number} Estrelas',
          loading: 'Carregando pontos...',
        },
        errors: {
          title: 'Erro',
          unauthorized: 'Não foi possível carregar o saldo: Não autorizado',
          notFound: 'Não foi possível carregar o saldo: Não encontrado',
          generic: 'Não foi possível carregar o saldo',
          updateFailed: 'Falha ao atualizar o saldo de pontos',
        },
      },
    },
    ru: {
      translation: {
        pointsBalance: {
          title: 'Ваш баланс очков',
          ariaLabel: 'Просмотр баланса очков',
          points: '{count, number} Звезды',
          loading: 'Загрузка очков...',
        },
        errors: {
          title: 'Ошибка',
          unauthorized: 'Не удалось загрузить баланс: Не авторизовано',
          notFound: 'Не удалось загрузить баланс: Не найдено',
          generic: 'Не удалось загрузить баланс',
          updateFailed: 'Не удалось обновить баланс очков',
        },
      },
    },
    it: {
      translation: {
        pointsBalance: {
          title: 'Il tuo saldo punti',
          ariaLabel: 'Visualizza saldo punti',
          points: '{count, number} Stelle',
          loading: 'Caricamento punti...',
        },
        errors: {
          title: 'Errore',
          unauthorized: 'Impossibile caricare il saldo: Non autorizzato',
          notFound: 'Impossibile caricare il saldo: Non trovato',
          generic: 'Impossibile caricare il saldo',
          updateFailed: 'Aggiornamento del saldo punti non riuscito',
        },
      },
    },
    nl: {
      translation: {
        pointsBalance: {
          title: 'Uw Puntenbalans',
          ariaLabel: 'Puntenbalans bekijken',
          points: '{count, number} Sterren',
          loading: 'Punten laden...',
        },
        errors: {
          title: 'Fout',
          unauthorized: 'Kan balans niet laden: Niet geautoriseerd',
          notFound: 'Kan balans niet laden: Niet gevonden',
          generic: 'Kan balans niet laden',
          updateFailed: 'Bijwerken van puntenbalans mislukt',
        },
      },
    },
    pl: {
      translation: {
        pointsBalance: {
          title: 'Twój bilans punktów',
          ariaLabel: 'Wyświetl bilans punktów',
          points: '{count, number} Gwiazdy',
          loading: 'Ładowanie punktów...',
        },
        errors: {
          title: 'Błąd',
          unauthorized: 'Nie udało się załadować bilansu: Brak autoryzacji',
          notFound: 'Nie udało się załadować bilansu: Nie znaleziono',
          generic: 'Nie udało się załadować bilansu',
          updateFailed: 'Nie udało się zaktualizować bilansu punktów',
        },
      },
    },
    tr: {
      translation: {
        pointsBalance: {
          title: 'Puan Bakiyeniz',
          ariaLabel: 'Puan bakiyesini görüntüle',
          points: '{count, number} Yıldız',
          loading: 'Puanlar yükleniyor...',
        },
        errors: {
          title: 'Hata',
          unauthorized: 'Bakiye yüklenemedi: Yetkisiz',
          notFound: 'Bakiye yüklenemedi: Bulunamadı',
          generic: 'Bakiye yüklenemedi',
          updateFailed: 'Puan bakiyesi güncellenemedi',
        },
      },
    },
    fa: {
      translation: {
        pointsBalance: {
          title: 'موجودی امتیازات شما',
          ariaLabel: 'مشاهده موجودی امتیازات',
          points: '{count, number} ستاره',
          loading: 'در حال بارگذاری امتیازات...',
        },
        errors: {
          title: 'خطا',
          unauthorized: 'نمی‌توان موجودی را بارگذاری کرد: غیرمجاز',
          notFound: 'نمی‌توان موجودی را بارگذاری کرد: یافت نشد',
          generic: 'نمی‌توان موجودی را بارگذاری کرد',
          updateFailed: 'به‌روزرسانی موجودی امتیازات ناموفق بود',
        },
      },
    },
    'zh-CN': {
      translation: {
        pointsBalance: {
          title: '您的积分余额',
          ariaLabel: '查看积分余额',
          points: '{count, number} 星',
          loading: '正在加载积分...',
        },
        errors: {
          title: '错误',
          unauthorized: '无法加载余额：未授权',
          notFound: '无法加载余额：未找到',
          generic: '无法加载余额',
          updateFailed: '更新积分余额失败',
        },
      },
    },
    vi: {
      translation: {
        pointsBalance: {
          title: 'Số dư điểm của bạn',
          ariaLabel: 'Xem số dư điểm',
          points: '{count, number} Sao',
          loading: 'Đang tải điểm...',
        },
        errors: {
          title: 'Lỗi',
          unauthorized: 'Không thể tải số dư: Không được ủy quyền',
          notFound: 'Không thể tải số dư: Không tìm thấy',
          generic: 'Không thể tải số dư',
          updateFailed: 'Cập nhật số dư điểm thất bại',
        },
      },
    },
    id: {
      translation: {
        pointsBalance: {
          title: 'Saldo Poin Anda',
          ariaLabel: 'Lihat saldo poin',
          points: '{count, number} Bintang',
          loading: 'Memuat poin...',
        },
        errors: {
          title: 'Kesalahan',
          unauthorized: 'Tidak dapat memuat saldo: Tidak diizinkan',
          notFound: 'Tidak dapat memuat saldo: Tidak ditemukan',
          generic: 'Tidak dapat memuat saldo',
          updateFailed: 'Gagal memperbarui saldo poin',
        },
      },
    },
    cs: {
      translation: {
        pointsBalance: {
          title: 'Váš bodový zůstatek',
          ariaLabel: 'Zobrazit bodový zůstatek',
          points: '{count, number} Hvězdy',
          loading: 'Načítání bodů...',
        },
        errors: {
          title: 'Chyba',
          unauthorized: 'Nelze načíst zůstatek: Neoprávněno',
          notFound: 'Nelze načíst zůstatek: Nenalezeno',
          generic: 'Nelze načíst zůstatek',
          updateFailed: 'Aktualizace bodového zůstatku selhala',
        },
      },
    },
    ar: {
      translation: {
        pointsBalance: {
          title: 'رصيد نقاطك',
          ariaLabel: 'عرض رصيد النقاط',
          points: '{count, number} نجوم',
          loading: 'جارٍ تحميل النقاط...',
        },
        errors: {
          title: 'خطأ',
          unauthorized: 'غير قادر على تحميل الرصيد: غير مصرح',
          notFound: 'غير قادر على تحميل الرصيد: غير موجود',
          generic: 'غير قادر على تحميل الرصيد',
          updateFailed: 'فشل في تحديث رصيد النقاط',
        },
      },
    },
    ko: {
      translation: {
        pointsBalance: {
          title: '포인트 잔액',
          ariaLabel: '포인트 잔액 보기',
          points: '{count, number} 별',
          loading: '포인트 로드 중...',
        },
        errors: {
          title: '오류',
          unauthorized: '잔액을 로드할 수 없습니다: 인증되지 않음',
          notFound: '잔액을 로드할 수 없습니다: 찾을 수 없음',
          generic: '잔액을 로드할 수 없습니다',
          updateFailed: '포인트 잔액 업데이트 실패',
        },
      },
    },
    uk: {
      translation: {
        pointsBalance: {
          title: 'Ваш баланс балів',
          ariaLabel: 'Переглянути баланс балів',
          points: '{count, number} Зірки',
          loading: 'Завантаження балів...',
        },
        errors: {
          title: 'Помилка',
          unauthorized: 'Не вдалося завантажити баланс: Не авторизовано',
          notFound: 'Не вдалося завантажити баланс: Не знайдено',
          generic: 'Не вдалося завантажити баланс',
          updateFailed: 'Не вдалося оновити баланс балів',
        },
      },
    },
    hu: {
      translation: {
        pointsBalance: {
          title: 'Pont egyenleged',
          ariaLabel: 'Pont egyenleg megtekintése',
          points: '{count, number} Csillag',
          loading: 'Pontok betöltése...',
        },
        errors: {
          title: 'Hiba',
          unauthorized: 'Nem sikerült betölteni az egyenleget: Nem engedélyezett',
          notFound: 'Nem sikerült betölteni az egyenleget: Nem található',
          generic: 'Nem sikerült betölteni az egyenleget',
          updateFailed: 'Nem sikerült frissíteni a pont egyenleget',
        },
      },
    },
    sv: {
      translation: {
        pointsBalance: {
          title: 'Ditt poängsaldo',
          ariaLabel: 'Visa poängsaldo',
          points: '{count, number} Stjärnor',
          loading: 'Laddar poäng...',
        },
        errors: {
          title: 'Fel',
          unauthorized: 'Kunde inte ladda saldot: Obehörig',
          notFound: 'Kunde inte ladda saldot: Hittades inte',
          generic: 'Kunde inte ladda saldot',
          updateFailed: 'Misslyckades med att uppdatera poängsaldot',
        },
      },
    },
    he: {
      translation: {
        pointsBalance: {
          title: 'יתרת הנקודות שלך',
          ariaLabel: 'צפה ביתרת הנקודות',
          points: '{count, number} כוכבים',
          loading: 'טוען נקודות...',
        },
        errors: {
          title: 'שגיאה',
          unauthorized: 'לא ניתן לטעון את היתרה: לא מורשה',
          notFound: 'לא ניתן לטעון את היתרה: לא נמצא',
          generic: 'לא ניתן לטעון את היתרה',
          updateFailed: 'עדכון יתרת הנקודות נכשל',
        },
      },
    },
  },
  lng: 'en',
  fallbackLng: 'en',
  interpolation: {
    escapeValue: false,
  },
});
```

This updated `i18n.js` includes translations for all 22 languages, matching the proposed `program_settings.branding` points labels. The `points` key uses `{count, number}` for proper pluralization, and RTL languages (`ar`, `he`) are handled in the frontend via the existing `isRTL` logic in `points-balance.jsx`.

### Integration with Points Balance (US-CW1)

The Points Balance component (`points-balance.jsx`) already supports multilingual rendering via i18next and RTL via `isRTL = i18n.language === 'ar'`. To fully support the new languages:

1. **Update API Fetch**: Modify the API call to `/points.v1/GetPointsBalance` to include the merchant’s supported languages from `merchants.language`. The backend should return the `program_settings.branding.points_label` for the requested language.
   ```javascript
   useEffect(() => {
     const fetchPointsBalance = async () => {
       try {
         const response = await fetch('/points.v1/GetPointsBalance', {
           headers: {
             'Content-Type': 'application/json',
             'Accept-Language': i18n.language, // Pass current language
           },
         });
         if (!response.ok) {
           throw new Error(response.status === 401 ? t('errors.unauthorized') : t('errors.notFound'));
         }
         const data = await response.json();
         setPoints(data.points);
         // Optionally update i18n with backend points label
         i18n.addResourceBundle(i18n.language, 'translation', {
           pointsBalance: { points: `{count, number} ${data.points_label || t('pointsBalance.points')}` },
         });
         setLoading(false);
       } catch (err) {
         setError(err.message || t('errors.generic'));
         setLoading(false);
       }
     };
     fetchPointsBalance();
   }, [t, i18n.language]);
   ```

2. **RTL Handling**: The existing `isRTL` logic should be updated to check `merchants.language.rtl`:
   ```javascript
   const isRTL = ['ar', 'he'].includes(i18n.language);
   ```

3. **Accessibility**: Ensure ARIA labels are localized (already handled via `t('pointsBalance.ariaLabel')`) and test keyboard navigation for all languages, especially RTL.

### Testing Considerations

To verify the multilingual and RTL support:
- **Unit Tests (Jest)**: Test `PointsBalance` component rendering for each language, ensuring correct points label and error messages.
  ```javascript
  test('renders PointsBalance with Japanese', () => {
    i18n.changeLanguage('ja');
    render(<PointsBalance />);
    expect(screen.getByText('あなたのポイント残高')).toBeInTheDocument();
  });
  ```
- **E2E Tests (Cypress)**: Test display flow for all 22 languages, including RTL rendering for `ar` and `he`.
  ```javascript
  it('displays Points Balance in Arabic with RTL', () => {
    cy.visit('/points-balance', { headers: { 'Accept-Language': 'ar' } });
    cy.get('[aria-label="عرض رصيد النقاط"]').should('have.css', 'direction', 'rtl');
  });
  ```
- **Load Tests (k6)**: Verify performance for 10,000 concurrent requests with varying `Accept-Language` headers.
- **Database Tests**: Query `merchants.language`, `program_settings.branding`, and `customer_segments.name` to ensure all 22 languages are stored and retrievable.

### Conclusion

The database schema requires minimal revisions to support the expanded language set and RTL requirements for i18next integration. The proposed changes include:
1. Updating `merchants.language` to include all 22 languages and RTL for `ar` and `he`.
2. Adding validation constraints for JSONB localized fields.
3. Enhancing `program_settings.branding` with default points labels for all languages.
4. Updating `calculate_rfm_score` for localized segment names.
5. Adding RTL metadata to `program_settings.accessibility_settings`.

These changes ensure the backend supports the Points Balance component (US-CW1) and other multilingual features (e.g., US-CW16, US-MD19, US-MD20, US-MD21) while maintaining performance and GDPR/CCPA compliance. The frontend i18next configuration has been updated to include all languages, and the existing `points-balance.jsx` code requires only minor adjustments to fetch localized points labels from the backend.

If you need further assistance with implementing these changes, writing migration scripts, or setting up additional components (e.g., Merchant Dashboard settings for language selection), let me know!